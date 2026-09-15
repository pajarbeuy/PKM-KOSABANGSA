<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class LandingContent extends Model
{
    use HasFactory;

    protected $fillable = ['section', 'content'];

    public static function getBySection($section)
    {
        return self::where('section', $section)->first()?->content ?? '';
    }
}
