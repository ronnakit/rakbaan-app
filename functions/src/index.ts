// Cloud Functions enforcing the recordStatus lifecycle designed in
// rakbaan_md/12-database-structure-front-end.md §1.5 and written up in full
// in rakbaan_md/14-firestore-security-rules-and-functions.md §3.
//
// NOT YET TESTED against the Firebase Emulator Suite -- see that doc's §4
// for the full list of what's still missing before this is production-ready
// (custom-claim role assignment, sub-collection loggers for
// boq_items/milestones/photos, Kill Switch authority/SLA decision, timezone
// on the scheduled purge).

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, FieldValue, Transaction } from "firebase-admin/firestore";

initializeApp();
const db = getFirestore();

// ---------- ตาราง transition ที่อนุญาต (ตาม §1.5.1) ----------
const ALLOWED_TRANSITIONS: Record<number, number[]> = {
  0: [1, 2, 3, 4, 5],
  1: [0, 2, 4, 5],
  2: [0, 1, 4, 5],
  3: [0, 4, 5],
  4: [0, 5],
  5: [0], // restore เท่านั้น
};

// role ขั้นต่ำที่อนุญาตให้ "ตั้งเป็น" สถานะนี้ (ไม่ใช่ role ของสถานะปัจจุบัน)
const MIN_ROLE_FOR_TARGET_STATUS: Record<number, string[]> = {
  0: ["team", "admin", "super_admin"], // restore
  1: ["team", "admin", "super_admin"], // read-only lock
  2: ["team", "admin", "super_admin"], // restrict
  4: ["team", "admin", "super_admin"], // staff delete
  5: ["super_admin"],                  // admin purge
};

interface SetRecordStatusInput {
  collectionPath: string; // "jobs", "jobs/RB-001/milestones", "escrow_transactions" ฯลฯ
  docId: string;
  newStatus: number;
  reason?: string;
}

/**
 * ทางเดียวที่ team/admin เปลี่ยน recordStatus ได้ (นอกจาก self-delete ของ client)
 * เขียน recordStatus + database_edit_log แบบ atomic ในทรานแซกชันเดียวกันเสมอ
 */
export const setRecordStatus = onCall<SetRecordStatusInput>({ region: "asia-southeast1" }, async (request) => {
  const auth = request.auth;
  if (!auth) throw new HttpsError("unauthenticated", "ต้อง login ก่อน");

  const role = (auth.token.role as string) ?? "customer";
  const { collectionPath, docId, newStatus, reason } = request.data;

  if (role === "customer") {
    throw new HttpsError(
      "permission-denied",
      "ลูกค้าใช้ self-delete (0→3) ผ่านการเขียน Firestore ตรงตาม Security Rules ไม่ต้องเรียกฟังก์ชันนี้"
    );
  }

  const allowedRoles = MIN_ROLE_FOR_TARGET_STATUS[newStatus];
  if (!allowedRoles || !allowedRoles.includes(role)) {
    throw new HttpsError("permission-denied", `role '${role}' ตั้ง recordStatus เป็น ${newStatus} ไม่ได้`);
  }

  const docRef = db.doc(`${collectionPath}/${docId}`);

  await db.runTransaction(async (tx: Transaction) => {
    const snap = await tx.get(docRef);
    if (!snap.exists) throw new HttpsError("not-found", "ไม่พบเอกสาร");

    const previousStatus: number = snap.data()?.recordStatus ?? 0;
    const allowedTargets = ALLOWED_TRANSITIONS[previousStatus] ?? [];
    if (!allowedTargets.includes(newStatus)) {
      throw new HttpsError("failed-precondition", `เปลี่ยนจากสถานะ ${previousStatus} เป็น ${newStatus} ไม่ได้`);
    }

    tx.update(docRef, {
      recordStatus: newStatus,
      lastActorId: auth.uid,
      lastActorType: role,
    });

    tx.set(db.collection("database_edit_log").doc(), {
      targetCollection: collectionPath,
      targetDocId: docId,
      actorId: auth.uid,
      actorType: role,
      actionType: newStatus === 0 ? "RESTORE" : newStatus >= 3 ? "DELETE" : "UPDATE",
      previousStatus,
      newStatus,
      reason: reason ?? null,
      timestamp: FieldValue.serverTimestamp(),
    });
  });

  return { success: true };
});

// ---------- Trigger: log เฉพาะ path self-delete (0->3) ที่ client เขียนตรงผ่าน Security Rules ----------
// transition อื่นทั้งหมด setRecordStatus เขียน log ให้แล้วในทรานแซกชันเดียวกัน ไม่ต้องให้ trigger นี้ทำซ้ำ
function makeSelfDeleteLogger(collectionId: string) {
  return onDocumentWritten(`${collectionId}/{docId}`, async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!before || !after) return; // ข้าม create/delete เอกสารทั้งชิ้น

    const prevStatus = before.recordStatus;
    const newStatus = after.recordStatus;
    if (prevStatus === newStatus) return;
    if (!(prevStatus === 0 && newStatus === 3 && after.lastActorType === "customer")) return;

    await db.collection("database_edit_log").add({
      targetCollection: collectionId,
      targetDocId: event.params.docId,
      actorId: after.lastActorId,
      actorType: after.lastActorType,
      actionType: "DELETE",
      previousStatus: prevStatus,
      newStatus: newStatus,
      reason: null,
      timestamp: FieldValue.serverTimestamp(),
    });
  });
}

export const logSelfDelete_users = makeSelfDeleteLogger("users");
export const logSelfDelete_addresses = makeSelfDeleteLogger("addresses");
export const logSelfDelete_jobs = makeSelfDeleteLogger("jobs");
export const logSelfDelete_memberships = makeSelfDeleteLogger("memberships");
export const logSelfDelete_reviews = makeSelfDeleteLogger("reviews");
export const logSelfDelete_chatSessions = makeSelfDeleteLogger("chat_sessions");
// ⚠️ notifications/disputes ไม่มี self-delete path จริง (ดู firestore.rules — notifications สร้างโดยระบบ,
// disputes ปิด/แก้สถานะได้แค่ team/admin) จึงไม่ต้องมี logger คู่นี้
// ⚠️ boq_items/milestones/photos เป็น sub-collection ใต้ jobs/{jobId} ต้องเขียน path แบบ
// "jobs/{jobId}/boq_items/{docId}" แยกต่างหาก — ยังไม่ครอบคลุมในไฟล์นี้ (ทำ pattern เดียวกันได้)

// ---------- Scheduled Function: Purge ตาม Retention Schedule (§1.5.5) ----------
export const purgeExpiredRecords = onSchedule(
  { schedule: "every day 03:00", timeZone: "Asia/Bangkok", region: "asia-southeast1" },
  async () => {
  const now = Date.now();
  const REPAIR_GRACE_DAYS = 90;
  const CONSTRUCTION_GRACE_DAYS = 365;
  const DEFAULT_GRACE_DAYS = 90; // ตารางกลุ่ม A อื่นที่ไม่ใช่ jobs — ยังไม่ได้ถามเจ้าของธุรกิจแยก (ดู §1.5.5)

  const jobsSnap = await db.collection("jobs").where("recordStatus", "==", 5).get();
  for (const doc of jobsSnap.docs) {
    const graceDays = doc.data().jobType === "construction" ? CONSTRUCTION_GRACE_DAYS : REPAIR_GRACE_DAYS;
    await purgeIfExpired(doc.ref, "jobs", graceDays, now, /* checkFinancialHold */ true);
  }

  const OTHER_COLLECTIONS = ["users", "addresses", "memberships", "reviews", "notifications", "disputes", "chat_sessions"];
  for (const col of OTHER_COLLECTIONS) {
    const snap = await db.collection(col).where("recordStatus", "==", 5).get();
    for (const doc of snap.docs) {
      await purgeIfExpired(doc.ref, col, DEFAULT_GRACE_DAYS, now, false);
    }
  }
  // escrow_transactions: ไม่ auto-purge เลย — รอทนายยืนยันกำหนดเก็บตามกฎหมายบัญชีก่อน (§1.5.5)
});

async function purgeIfExpired(
  docRef: FirebaseFirestore.DocumentReference,
  collectionId: string,
  graceDays: number,
  now: number,
  checkFinancialHold: boolean
) {
  const logSnap = await db
    .collection("database_edit_log")
    .where("targetCollection", "==", collectionId)
    .where("targetDocId", "==", docRef.id)
    .where("newStatus", "==", 5)
    .orderBy("timestamp", "desc")
    .limit(1)
    .get();
  if (logSnap.empty) return; // ไม่พบเวลาที่ตั้ง status 5 ใน log — ข้ามไปก่อน (ผิดปกติตามดีไซน์ ควรมีเสมอ)

  const purgedAt = logSnap.docs[0].data().timestamp.toMillis();
  if (now - purgedAt < graceDays * 24 * 60 * 60 * 1000) return; // ยังไม่ครบ grace period

  const disputeSnap = await db
    .collection("disputes")
    .where("jobId", "==", docRef.id)
    .where("status", "in", ["open", "investigating"])
    .limit(1)
    .get();
  if (!disputeSnap.empty) return; // มี legal hold — เลื่อนการลบ

  if (checkFinancialHold) {
    const escrowSnap = await db.collection("escrow_transactions").where("jobId", "==", docRef.id).limit(1).get();
    if (!escrowSnap.empty) return; // มีธุรกรรมการเงินผูกอยู่ — ห้ามลบจนกว่าทนายยืนยันกำหนดเก็บ
  }

  await docRef.delete(); // ลบทางกายภาพจริง
}
