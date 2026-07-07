export interface QuoteRequest {
  name: string;
  phone: string;
  email: string;
  city: string;
  electricalSupplyType: 'monophasic-110' | 'biphasic-220' | 'triphasic' | 'single-phase-380';
  propertyType: 'residence' | 'condominium' | 'commercial';
  message: string;
}
