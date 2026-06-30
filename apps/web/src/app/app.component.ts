import { CommonModule } from '@angular/common';
import { Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { QuoteRequest } from './quote-request';
import { QuoteService } from './quote.service';

@Component({
  selector: 'foton-root',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule],
  templateUrl: './app.component.html',
  styleUrl: './app.component.css'
})
export class AppComponent {
  private readonly formBuilder = inject(FormBuilder);
  private readonly quoteService = inject(QuoteService);

  readonly sending = signal(false);
  readonly submitted = signal(false);
  readonly error = signal('');

  readonly quoteForm = this.formBuilder.nonNullable.group({
    name: ['', [Validators.required, Validators.minLength(3)]],
    phone: ['', [Validators.required, Validators.minLength(10)]],
    email: ['', [Validators.required, Validators.email]],
    city: ['', [Validators.required, Validators.minLength(2)]],
    installationType: ['both' as QuoteRequest['installationType'], [Validators.required]],
    needsElectricalStandard: [true],
    hasBiphasicNetwork: [true],
    message: ['']
  });

  submitQuote(): void {
    this.error.set('');
    this.submitted.set(false);

    if (this.quoteForm.invalid) {
      this.quoteForm.markAllAsTouched();
      return;
    }

    this.sending.set(true);
    this.quoteService.createQuote(this.quoteForm.getRawValue()).subscribe({
      next: () => {
        this.sending.set(false);
        this.submitted.set(true);
        this.quoteForm.reset({
          installationType: 'both',
          needsElectricalStandard: true,
          hasBiphasicNetwork: true,
          message: ''
        });
      },
      error: () => {
        this.sending.set(false);
        this.error.set('Nao foi possivel enviar agora. Tente novamente em instantes.');
      }
    });
  }
}
