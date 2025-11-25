@extends('layouts.guest')

@section('content')
<div class="login-box" style="width: 400px;">
    <div class="card card-outline card-primary">
        <div class="card-header text-center">
            <h1><b>VPS</b> Admin</h1>
        </div>
        <div class="card-body">
            <p class="login-box-msg">
                <i class="fas fa-shield-alt"></i>
                <strong>Two-Factor Authentication</strong>
            </p>
            
            <p class="text-muted text-center">
                Enter the 6-digit code from your authenticator app
            </p>

            @if($errors->any())
                <div class="alert alert-danger alert-dismissible">
                    <button type="button" class="close" data-dismiss="alert">&times;</button>
                    {{ $errors->first() }}
                </div>
            @endif

            <form method="POST" action="{{ route('two-factor.verify') }}">
                @csrf
                
                <div class="input-group mb-3">
                    <input type="text" 
                           class="form-control form-control-lg text-center @error('code') is-invalid @enderror" 
                           name="code" 
                           placeholder="000000"
                           maxlength="10"
                           required
                           autofocus
                           style="letter-spacing: 0.3em; font-size: 1.3em;">
                    <div class="input-group-append">
                        <div class="input-group-text">
                            <span class="fas fa-key"></span>
                        </div>
                    </div>
                    @error('code')
                        <span class="invalid-feedback d-block">{{ $message }}</span>
                    @enderror
                </div>

                <small class="form-text text-muted text-center mb-3">
                    You can also use a recovery code if you don't have access to your authenticator app
                </small>

                <div class="row">
                    <div class="col-12">
                        <button type="submit" class="btn btn-primary btn-block">
                            <i class="fas fa-sign-in-alt"></i> Verify
                        </button>
                    </div>
                </div>
            </form>

            <p class="mt-3 mb-1 text-center">
                <a href="{{ route('login') }}" class="text-muted">
                    <i class="fas fa-arrow-left"></i> Back to login
                </a>
            </p>
        </div>
    </div>
</div>

<script>
// Auto-submit form when 6 digits are entered
document.querySelector('input[name="code"]').addEventListener('input', function(e) {
    // Allow numbers and hyphens for recovery codes
    this.value = this.value.toUpperCase().replace(/[^0-9A-Z-]/g, '');
    
    // Auto-submit if exactly 6 digits (TOTP code)
    if (this.value.length === 6 && /^[0-9]{6}$/.test(this.value)) {
        this.form.submit();
    }
});
</script>
@endsection
