<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Represents an external OAuth identity (e.g. Google) linked to a local User.
 *
 * @property int    $id
 * @property int    $user_id
 * @property string $provider           e.g. 'google'
 * @property string $provider_user_id   Google's stable 'sub' claim
 */
class UserOauthIdentity extends Model
{
    protected $fillable = [
        'user_id',
        'provider',
        'provider_user_id',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
