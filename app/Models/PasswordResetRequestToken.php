<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PasswordResetRequestToken extends Model
{
    use HasFactory;

    protected $fillable = [
        'request_id',
        'user_id',
        'token_hash',
        'status',
        'expires_at',
        'used_at',
        'revoked_at',
        'revoked_by_admin_id',
    ];

    protected $casts = [
        'expires_at' => 'datetime',
        'used_at' => 'datetime',
        'revoked_at' => 'datetime',
    ];

    /**
     * The password reset request this token belongs to.
     */
    public function request(): BelongsTo
    {
        return $this->belongsTo(PasswordResetRequest::class, 'request_id');
    }

    /**
     * The user this token belongs to.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    /**
     * Admin who revoked this token (if applicable).
     */
    public function revokedByAdmin(): BelongsTo
    {
        return $this->belongsTo(User::class, 'revoked_by_admin_id');
    }

    /**
     * Check if token has expired past its 5-minute validity window.
     */
    public function isExpired(): bool
    {
        return $this->expires_at->isPast();
    }

    /**
     * Check if token is strictly valid and usable.
     */
    public function isValid(): bool
    {
        return $this->status === 'active' &&
            !$this->isExpired() &&
            $this->used_at === null &&
            $this->revoked_at === null;
    }
}
