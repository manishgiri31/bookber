export type Coordinates = {
  latitude: number;
  longitude: number;
};

export type NearbyShopsRequest = {
  latitude: number;
  longitude: number;
  radius?: number; // in kilometers
  city?: string;
  limit?: number;
  offset?: number;
  premiumOnly?: boolean; // Filter for shops with BookBer reserved chairs
  maxWaitMinutes?: number; // Filter by maximum estimated wait time
  sortBy?: 'distance' | 'wait' | 'rating' | 'premium'; // Sort preference
};

export type NearbyShop = {
  id: string;
  name: string;
  slug: string;
  description: string | null;
  address: string;
  city: string;
  state: string;
  country: string;
  latitude: number;
  longitude: number;
  distance: number; // in kilometers
  averageRating: number;
  reviewCount: number;
  isActive: boolean;
  isAcceptingBookings: boolean;
  isAcceptingWalkIns: boolean;
  profileImage: string | null;
  estimatedWaitMinutes: number | null;
  availableChairs: number;
};

export type MapMarker = {
  id: string;
  name: string;
  latitude: number;
  longitude: number;
  averageRating: number;
  isActive: boolean;
  shopId: string;
};

export type ShopCluster = {
  latitude: number;
  longitude: number;
  shopCount: number;
  shops: MapMarker[];
};

export type ETAEstimation = {
  shopId: string;
  distance: number; // in kilometers
  estimatedTravelTime: number; // in minutes
  estimatedArrivalTime: Date;
  mode: "walking" | "driving" | "transit";
};

export type GeolocationSearchParams = {
  latitude: number;
  longitude: number;
  radius?: number;
  city?: string;
  minRating?: number;
  acceptingBookings?: boolean;
  acceptingWalkIns?: boolean;
  premiumOnly?: boolean;
  maxWaitMinutes?: number;
  sortBy?: 'distance' | 'wait' | 'rating' | 'premium';
  limit?: number;
  offset?: number;
};

export type PaginationParams = {
  limit: number;
  offset: number;
};

export type PaginationResult<T> = {
  data: T[];
  total: number;
  limit: number;
  offset: number;
  hasMore: boolean;
};
