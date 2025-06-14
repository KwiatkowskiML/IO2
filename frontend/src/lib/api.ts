import axios from 'axios';
import type { AxiosInstance } from 'axios';
import type {
  User,
  Organizer,
  Event,
  Ticket,
  TicketType,
  CartItemWithDetails,
  ResaleTicketListing,
  LoginRequest,
  TokenResponse,
  RegisterCustomerRequest,
  RegisterOrganizerRequest,
  RegisterAdminRequest,
  CreateEventRequest,
  EventFilters,
  TicketFilters,
} from '@/types/api';

class ApiClient {
  private client: AxiosInstance;

  constructor() {
    this.client = axios.create({
      baseURL: 'http://localhost:8080/api',
      timeout: 10000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Add request interceptor to include auth token
    this.client.interceptors.request.use(
      (config) => {
        const token = localStorage.getItem('token');
        if (token) {
          config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
      },
      (error) => {
        return Promise.reject(error);
      }
    );

    // Add response interceptor to handle common errors
    this.client.interceptors.response.use(
      (response) => response,
      (error) => {
        if (error.response?.status === 401) {
          localStorage.removeItem('token');
          window.location.href = '/login';
        }
        return Promise.reject(error);
      }
    );
  }

  // Auth endpoints
  async login(credentials: LoginRequest): Promise<TokenResponse> {
    const formData = new FormData();
    formData.append('username', credentials.username);
    formData.append('password', credentials.password);
    
    const response = await this.client.post<TokenResponse>('/auth/token', formData, {
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
    });
    return response.data;
  }

  async registerCustomer(data: RegisterCustomerRequest): Promise<TokenResponse> {
    const response = await this.client.post<TokenResponse>('/auth/register/customer', data);
    return response.data;
  }

  async registerOrganizer(data: RegisterOrganizerRequest): Promise<TokenResponse> {
    const response = await this.client.post<TokenResponse>('/auth/register/organizer', data);
    return response.data;
  }

  async registerAdmin(data: RegisterAdminRequest): Promise<TokenResponse> {
    const response = await this.client.post<TokenResponse>('/auth/register/admin', data);
    return response.data;
  }

  async logout(): Promise<void> {
    await this.client.post('/auth/logout');
    localStorage.removeItem('token');
  }

  async getCurrentUser(): Promise<User | Organizer> {
    const response = await this.client.get<User | Organizer>('/user/me');
    return response.data;
  }

  async getPendingOrganizers(): Promise<Organizer[]> {
    const response = await this.client.get<Organizer[]>('/auth/pending-organizers');
    return response.data;
  }

  async verifyOrganizer(organizerId: number): Promise<Organizer> {
    const response = await this.client.post<Organizer>('/auth/verify-organizer', {
      organizer_id: organizerId,
    });
    return response.data;
  }

  async banUser(userId: number): Promise<void> {
    await this.client.post(`/auth/ban-user/${userId}`);
  }

  async unbanUser(userId: number): Promise<void> {
    await this.client.post(`/auth/unban-user/${userId}`);
  }

  // Event endpoints
  async getEvents(filters?: EventFilters): Promise<Event[]> {
    const response = await this.client.get<Event[]>('/events', {
      params: filters,
    });
    return response.data;
  }

  async createEvent(data: CreateEventRequest): Promise<Event> {
    const response = await this.client.post<Event>('/events/', data);
    return response.data;
  }

  async updateEvent(eventId: number, data: Partial<CreateEventRequest>): Promise<Event> {
    const response = await this.client.put<Event>(`/events/${eventId}`, data);
    return response.data;
  }

  async cancelEvent(eventId: number): Promise<void> {
    await this.client.delete(`/events/${eventId}`);
  }

  async authorizeEvent(eventId: number): Promise<void> {
    await this.client.post(`/events/authorize/${eventId}`);
  }

  async notifyEventParticipants(eventId: number, message: string): Promise<void> {
    await this.client.post(`/events/${eventId}/notify`, { message });
  }

  // Ticket endpoints
  async getTickets(filters?: TicketFilters): Promise<Ticket[]> {
    const response = await this.client.get<Ticket[]>('/tickets/', {
      params: filters,
    });
    return response.data;
  }

  async downloadTicket(ticketId: number): Promise<string> {
    const response = await this.client.get(`/tickets/${ticketId}/download`);
    return response.data.pdf_data;
  }

  async resellTicket(ticketId: number, price: number): Promise<Ticket> {
    const response = await this.client.post<Ticket>(`/tickets/${ticketId}/resell`, {
      resell_price: price,
    });
    return response.data;
  }

  async cancelResellTicket(ticketId: number): Promise<Ticket> {
    const response = await this.client.delete<Ticket>(`/tickets/${ticketId}/resell`);
    return response.data;
  }

  // Ticket type endpoints
  async getTicketTypes(eventId?: number): Promise<TicketType[]> {
    const response = await this.client.get<TicketType[]>('/ticket-types/', {
      params: eventId ? { event_id: eventId } : {},
    });
    return response.data;
  }

  async createTicketType(data: Omit<TicketType, 'type_id'>): Promise<TicketType> {
    const response = await this.client.post<TicketType>('/ticket-types/', data);
    return response.data;
  }

  async deleteTicketType(typeId: number): Promise<void> {
    await this.client.delete(`/ticket-types/${typeId}`);
  }

  // Cart endpoints
  async getCartItems(): Promise<CartItemWithDetails[]> {
    const response = await this.client.get<CartItemWithDetails[]>('/cart/items');
    return response.data;
  }

  async addToCart(ticketTypeId: number, quantity: number = 1): Promise<CartItemWithDetails> {
    const response = await this.client.post<CartItemWithDetails>('/cart/items', null, {
      params: { ticket_type_id: ticketTypeId, quantity },
    });
    return response.data;
  }

  async removeFromCart(cartItemId: number): Promise<void> {
    await this.client.delete(`/cart/items/${cartItemId}`);
  }

  async checkout(): Promise<void> {
    await this.client.post('/cart/checkout');
  }

  // Resale endpoints
  async getResaleMarketplace(eventId?: number, minPrice?: number, maxPrice?: number): Promise<ResaleTicketListing[]> {
    const response = await this.client.get<ResaleTicketListing[]>('/resale/marketplace', {
      params: { event_id: eventId, min_price: minPrice, max_price: maxPrice },
    });
    return response.data;
  }

  async purchaseResaleTicket(ticketId: number): Promise<Ticket> {
    const response = await this.client.post<Ticket>('/resale/purchase', {
      ticket_id: ticketId,
    });
    return response.data;
  }

  async getMyResaleListings(): Promise<ResaleTicketListing[]> {
    const response = await this.client.get<ResaleTicketListing[]>('/resale/my-listings');
    return response.data;
  }
}

export const apiClient = new ApiClient(); 