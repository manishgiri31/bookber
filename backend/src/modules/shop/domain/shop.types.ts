export type ShopStatus = "ACTIVE" | "INACTIVE";
export type ChairStatus = "AVAILABLE" | "OCCUPIED" | "CLEANING" | "BLOCKED";
export type ServiceStatus = "ACTIVE" | "INACTIVE";

export type ShopDTO = {
  id: string;
  name: string;
  description: string | null;
  address: string;
  city: string;
  state: string;
  country: string;
  latitude: number;
  longitude: number;
  openingTime: string | null;
  closingTime: string | null;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
};

export type ShopWithRelations = ShopDTO & {
  services: ServiceDTO[];
  chairs: ChairDTO[];
};

export type ServiceDTO = {
  id: string;
  shopId: string;
  name: string;
  description: string | null;
  price: number;
  durationMinutes: number;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
};

export type ChairDTO = {
  id: string;
  shopId: string;
  number: number;
  status: ChairStatus;
  createdAt: Date;
};

export type PaginationParams = {
  page: number;
  limit: number;
};

export type PaginationResult<T> = {
  data: T[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
};

export type ShopSearchParams = {
  query?: string;
  city?: string;
  isActive?: boolean;
  latitude?: number;
  longitude?: number;
  radiusKm?: number;
} & PaginationParams;

export type ServiceSearchParams = {
  shopId: string;
  query?: string;
  isActive?: boolean;
} & PaginationParams;
