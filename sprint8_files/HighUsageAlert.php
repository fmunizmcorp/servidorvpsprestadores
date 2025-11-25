<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class HighUsageAlert extends Mailable
{
    use Queueable, SerializesModels;

    /**
     * Alert data containing usage metrics
     *
     * @var array
     */
    public $alertData;

    /**
     * Create a new message instance.
     */
    public function __construct($alertData)
    {
        $this->alertData = $alertData;
    }

    /**
     * Get the message envelope.
     */
    public function envelope(): Envelope
    {
        return new Envelope(
            subject: '🚨 High Resource Usage Alert - VPS 72.61.53.222',
        );
    }

    /**
     * Get the message content definition.
     */
    public function content(): Content
    {
        return new Content(
            view: 'emails.high-usage-alert',
        );
    }

    /**
     * Get the attachments for the message.
     *
     * @return array<int, \Illuminate\Mail\Mailables\Attachment>
     */
    public function attachments(): array
    {
        return [];
    }
}
