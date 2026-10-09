<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class PasswordResetRequest extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'name',
        'farmer_group_name',
        'farmer_group_id',
        'status',
        'admin_id',
        'approved_at',
        'rejected_at',
        'rejection_reason',
        'completed_at',
        'ip_address',
        'user_agent',
    ];

    protected $casts = [
        'approved_at' => 'datetime',
        'rejected_at' => 'datetime',
        'completed_at' => 'datetime',
    ];

    /**
     * User associated with this request.
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    /**
     * Admin who approved or rejected this request.
     */
    public function admin(): BelongsTo
    {
        return $this->belongsTo(User::class, 'admin_id');
    }

    /**
     * Farmer group associated with this request.
     */
    public function farmerGroup(): BelongsTo
    {
        return $this->belongsTo(FarmerGroup::class, 'farmer_group_id');
    }

    /**
     * Tokens generated for this request.
     */
    public function tokens(): HasMany
    {
        return $this->hasMany(PasswordResetRequestToken::class, 'request_id');
    }

    /**
     * Current active token for this request.
     */
    public function activeToken(): HasOne
    {
        return $this->hasOne(PasswordResetRequestToken::class, 'request_id')
            ->where('status', 'active')
            ->where('expires_at', '>', now());
    }

    /**
     * Scope for pending requests.
     */
    public function scopePending($query)
    {
        return $query->where('status', 'pending');
    }

    /**
     * Scope for approved requests.
     */
    public function scopeApproved($query)
    {
        return $query->where('status', 'approved');
    }

    /**
     * Scope for rejected requests.
     */
    public function scopeRejected($query)
    {
        return $query->where('status', 'rejected');
    }

    /**
     * Scope for completed requests.
     */
    public function scopeCompleted($query)
    {
        return $query->where('status', 'completed');
    }
}
