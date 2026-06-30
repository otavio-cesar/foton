import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { QuoteRequest } from './quote-request';

@Injectable({ providedIn: 'root' })
export class QuoteService {
  private readonly endpoint = '/api/quotes';

  constructor(private readonly http: HttpClient) {}

  createQuote(request: QuoteRequest): Observable<{ id: string; status: string }> {
    return this.http.post<{ id: string; status: string }>(this.endpoint, request);
  }
}
