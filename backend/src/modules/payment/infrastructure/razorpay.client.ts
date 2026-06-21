import crypto from "node:crypto";
import { createModuleLogger } from "../../../infrastructure/logging/structured-logger.js";

const log = createModuleLogger("razorpay-client");

const RAZORPAY_API = "https://api.razorpay.com/v1";

export type RazorpayOrder = {
  id: string;
  entity: string;
  amount: number;
  amount_paid: number;
  amount_due: number;
  currency: string;
  receipt: string;
  status: string;
  created_at: number;
};

export class RazorpayClient {
  private readonly keyId: string;
  private readonly keySecret: string;
  private readonly enabled: boolean;

  constructor() {
    this.keyId = process.env["RAZORPAY_KEY_ID"] ?? "";
    this.keySecret = process.env["RAZORPAY_KEY_SECRET"] ?? "";
    this.enabled =
      !!this.keyId &&
      !!this.keySecret &&
      this.keyId !== "placeholder" &&
      this.keySecret !== "placeholder";

    if (!this.enabled) {
      log.warn(
        "Razorpay keys not configured — payment gateway running in stub mode. " +
          "Set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET in .env to enable real payments."
      );
    }
  }

  get isEnabled(): boolean {
    return this.enabled;
  }

  async createOrder(params: {
    amount: number;
    currency: string;
    receipt: string;
    notes?: Record<string, string>;
  }): Promise<RazorpayOrder> {
    if (!this.enabled) {
      return this._stubOrder(params.amount, params.currency, params.receipt);
    }

    const auth = Buffer.from(`${this.keyId}:${this.keySecret}`).toString("base64");
    const res = await fetch(`${RAZORPAY_API}/orders`, {
      method: "POST",
      headers: {
        "Authorization": `Basic ${auth}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        amount: Math.round(params.amount * 100), // Razorpay uses paise
        currency: params.currency,
        receipt: params.receipt,
        notes: params.notes ?? {},
      }),
    });

    if (!res.ok) {
      const err = await res.text();
      log.error({ status: res.status, err }, "Razorpay order creation failed");
      throw new Error(`Razorpay order failed: ${res.status}`);
    }

    return res.json() as Promise<RazorpayOrder>;
  }

  verifySignature(params: {
    razorpayOrderId: string;
    razorpayPaymentId: string;
    razorpaySignature: string;
  }): boolean {
    if (!this.enabled) return true; // stub: always valid

    const body = `${params.razorpayOrderId}|${params.razorpayPaymentId}`;
    const expected = crypto
      .createHmac("sha256", this.keySecret)
      .update(body)
      .digest("hex");

    return crypto.timingSafeEqual(
      Buffer.from(expected, "hex"),
      Buffer.from(params.razorpaySignature, "hex")
    );
  }

  verifyWebhookSignature(payload: string, signature: string): boolean {
    if (!this.enabled) return true;

    const expected = crypto
      .createHmac("sha256", process.env["RAZORPAY_WEBHOOK_SECRET"] ?? this.keySecret)
      .update(payload)
      .digest("hex");

    return expected === signature;
  }

  private _stubOrder(amount: number, currency: string, receipt: string): RazorpayOrder {
    const stubId = `stub_order_${Date.now()}`;
    return {
      id: stubId,
      entity: "order",
      amount: Math.round(amount * 100),
      amount_paid: 0,
      amount_due: Math.round(amount * 100),
      currency,
      receipt,
      status: "created",
      created_at: Math.floor(Date.now() / 1000),
    };
  }
}

let _instance: RazorpayClient | null = null;
export function getRazorpayClient(): RazorpayClient {
  if (!_instance) _instance = new RazorpayClient();
  return _instance;
}
