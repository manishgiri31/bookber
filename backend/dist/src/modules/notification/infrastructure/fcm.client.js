import admin from "firebase-admin";
import { env } from "../../../shared/config/env.js";
let initialized = false;
export function getFcmApp() {
    if (!initialized) {
        admin.initializeApp({
            credential: admin.credential.cert({
                projectId: env.FCM_PROJECT_ID ?? "",
                clientEmail: env.FCM_CLIENT_EMAIL ?? "",
                privateKey: (env.FCM_PRIVATE_KEY ?? "").replace(/\\n/g, "\n")
            })
        });
        initialized = true;
    }
    return admin.app();
}
export function getMessaging() {
    return getFcmApp().messaging();
}
