<?php

namespace App\Http\Requests;

use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class ProfileUpdateRequest extends FormRequest
{
    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, \Illuminate\Contracts\Validation\ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'name' => [
                'required', 
                'string', 
                'max:255',
                'regex:/^[a-zA-Z0-9\s\-\_\.]+$/'  // XSS Fix: Only allow alphanumeric, spaces, and safe chars
            ],
            'email' => [
                'required',
                'string',
                'lowercase',
                'email',
                'max:255',
                Rule::unique(User::class)->ignore($this->user()->id),
            ],
        ];
    }
    
    /**
     * Get custom validation messages
     */
    public function messages(): array
    {
        return [
            'name.regex' => 'The name field can only contain letters, numbers, spaces, hyphens, underscores, and dots.',
        ];
    }
}
