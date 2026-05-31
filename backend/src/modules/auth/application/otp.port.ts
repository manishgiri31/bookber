export type OtpPurpose = "LOGIN" | "REGISTER" | "PASSWORD_RESET" | "PHONE_VERIFY";

export type OtpChallengeInput = {
  destination: string;
  channel: "SMS" | "EMAIL";
  purpose: OtpPurpose;
  code: string;
  expiresAt: Date;
};

export interface OtpPort {
  createChallenge(input: OtpChallengeInput): Promise<string>;
  verifyChallenge(input: { destination: string; purpose: OtpPurpose; code: string }): Promise<boolean>;
}
