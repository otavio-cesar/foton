export interface QuoteRequest {
  name: string;
  phone: string;
  email: string;
  city: string;
  installationType: 'charger' | 'totem' | 'both' | 'not-sure';
  needsElectricalStandard: boolean;
  hasBiphasicNetwork: boolean;
  message: string;
}
