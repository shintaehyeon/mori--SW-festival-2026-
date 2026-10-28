import { z } from "zod";
const text = (n = 1000) => z.string().trim().max(n);
const date = z.iso.date();
export const knowledge = z
  .object({ status: z.enum(["none", "unknown", "known"]), detail: text(300) })
  .refine(
    (v) => v.status !== "known" || v.detail.length > 0,
    "Please enter details.",
  );
export const profileSchema = z.object({
  allergies: knowledge,
  medications: knowledge,
});
export const journalSchema = z.object({
  date,
  condition: z.enum(["good", "okay", "low"]),
  sleep: z.number().min(0).max(24),
  note: text(1000),
  intakes: z.array(z.enum(["alcohol","vitamin_c","medication","supplement"])).max(4).refine(v => new Set(v).size === v.length,"Duplicate intake selection.").optional(),
});
export const symptomSchema = z.object({
  symptoms: text(2000).min(2),
  onset: text(200).min(1),
  journalIds: z.array(z.string().uuid()).max(7),
  consent: z.literal(true),
  intake: z.object({patientName:text(120),bodySite:text(120),painScore:z.number().int().min(0).max(10).nullable(),temperatureC:z.number().min(30).max(45).nullable(),measuredAt:text(120)}).optional(),
});
export const postSchema = z.object({
  title: text(120).min(3),
  body: text(3000).min(10),
  place: text(120).min(1),
  visitDate: date,
  language: z.enum(["English", "Korean", "Other"]),
  method: z.enum(["direct", "translation", "friend"]),
  consent: z.literal(true),
});
export const commentSchema = z.object({ body: text(1000).min(1) });
export const reportSchema = z.object({
  reason: z.enum(["privacy", "misinformation", "spam", "other"]),
  detail: text(500),
});
export const registerSchema = z.object({
  email: z
    .email()
    .max(254)
    .transform((v) => v.toLowerCase()),
  password: z.string().min(10).max(128),
  nickname: text(30).min(2),
});
export const loginSchema = z.object({
  email: z
    .email()
    .max(254)
    .transform((v) => v.toLowerCase()),
  password: z.string().min(1).max(128),
});
export const translationSchema = z.object({
  symptomsKo: text(4000).min(1),
  onsetKo: text(500).min(1),
  allergiesKo: text(1000).min(1),
  medicationsKo: text(1000).min(1),
  journalKo: z.array(z.object({ id: z.string(), textKo: text(2000) })).max(7),
});
export const cardConfirmSchema = z.object({
  symptomsKo: text(4000),
  onsetKo: text(500),
  allergiesKo: text(1000),
  medicationsKo: text(1000),
  journalKo: z.array(z.object({ id: z.string(), textKo: text(2000) })).max(7),
  reviewed: z.literal(true),
});
export function parse(schema, data) {
  const result = schema.safeParse(data);
  if (!result.success) {
    const error = new Error(
      result.error.issues
        .map((i) => `${i.path.join(".")}: ${i.message}`)
        .join("; "),
    );
    error.status = 400;
    throw error;
  }
  return result.data;
}
export function assertNumbersPreserved(source, translated) {
  const numbers = source.match(/\d+(?:\.\d+)?/g) || [];
  const output = translated.match(/\d+(?:\.\d+)?/g) || [];
  if (numbers.some((n) => !output.includes(n))) {
    const error = new Error(
      "Translation changed or omitted a number. Please retry or use the original card.",
    );
    error.status = 422;
    throw error;
  }
}

export const emergencySchema = z.object({
  name: text(120), nationality: text(100), organization: text(200), address: text(500),
  location: text(500), activity: text(300), symptoms: text(1000),
  message: text(2000), updatedAt: z.iso.datetime(),
  contacts: z.array(z.object({name: text(100), phone: z.string().trim().regex(/^\+?[0-9 ()-]{6,25}$/)})).max(5),
});

export const avatarSchema = z.object({
  name: text(20).min(1), style: z.enum(["sprout", "cat", "bunny"]), color: z.enum(["mint", "peach", "lavender"]),
});

export const presenceSettingsSchema = z.union([
 z.object({enabled:z.boolean(),organizationType:z.enum(["school","work","other"]),organization:text(120),region:text(120)})
 .refine(v=>!v.enabled || v.organization.length>0 || v.region.length>0,"Enter your organization or region."),
 z.object({handong:z.boolean()}).transform(v=>({enabled:v.handong,organizationType:"school",organization:v.handong?"한동대학교":"",region:""})),
]);
export const presenceSchema = z.object({clientId:z.string().regex(/^[A-Za-z0-9-]{8,80}$/)});
