<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use PragmaRX\Google2FA\Google2FA;
use BaconQrCode\Renderer\ImageRenderer;
use BaconQrCode\Renderer\Image\SvgImageBackEnd;
use BaconQrCode\Renderer\RendererStyle\RendererStyle;
use BaconQrCode\Writer;

class TwoFactorController extends Controller
{
    protected $google2fa;

    public function __construct()
    {
        $this->google2fa = new Google2FA();
    }

    /**
     * Show 2FA setup page
     */
    public function show()
    {
        $user = Auth::user();
        
        // If 2FA is already enabled, show disable option
        if ($user->hasTwoFactorEnabled()) {
            return view('auth.two-factor.show', [
                'enabled' => true,
            ]);
        }

        return view('auth.two-factor.show', [
            'enabled' => false,
        ]);
    }

    /**
     * Enable 2FA - generate secret and QR code
     */
    public function enable()
    {
        $user = Auth::user();

        // Generate secret key
        $secret = $this->google2fa->generateSecretKey();

        // Store temporarily in session (not in database yet)
        session(['2fa_secret' => $secret]);

        // Generate QR code URL
        $qrCodeUrl = $this->google2fa->getQRCodeUrl(
            config('app.name'),
            $user->email,
            $secret
        );

        // Generate QR code SVG
        $renderer = new ImageRenderer(
            new RendererStyle(200),
            new SvgImageBackEnd()
        );
        $writer = new Writer($renderer);
        $qrCodeSvg = $writer->writeString($qrCodeUrl);

        return view('auth.two-factor.enable', [
            'secret' => $secret,
            'qrCodeSvg' => $qrCodeSvg,
        ]);
    }

    /**
     * Confirm 2FA setup by verifying code
     */
    public function confirm(Request $request)
    {
        $request->validate([
            'code' => 'required|numeric|digits:6',
        ]);

        $user = Auth::user();
        $secret = session('2fa_secret');

        if (!$secret) {
            return redirect()->route('two-factor.show')
                ->with('error', '2FA setup session expired. Please start again.');
        }

        // Verify the code
        $valid = $this->google2fa->verifyKey($secret, $request->code);

        if (!$valid) {
            return back()->withErrors(['code' => 'Invalid verification code. Please try again.']);
        }

        // Generate recovery codes
        $recoveryCodes = $user->generateRecoveryCodes();

        // Save 2FA settings to database
        $user->update([
            'two_factor_enabled' => true,
            'two_factor_secret' => encrypt($secret),
            'two_factor_recovery_codes' => $recoveryCodes,
        ]);

        // Clear session
        session()->forget('2fa_secret');

        return view('auth.two-factor.recovery-codes', [
            'recoveryCodes' => $recoveryCodes,
        ]);
    }

    /**
     * Disable 2FA
     */
    public function disable(Request $request)
    {
        $request->validate([
            'password' => 'required',
        ]);

        $user = Auth::user();

        // Verify password
        if (!\Hash::check($request->password, $user->password)) {
            return back()->withErrors(['password' => 'Invalid password.']);
        }

        // Disable 2FA
        $user->update([
            'two_factor_enabled' => false,
            'two_factor_secret' => null,
            'two_factor_recovery_codes' => null,
        ]);

        return redirect()->route('two-factor.show')
            ->with('success', 'Two-factor authentication has been disabled.');
    }

    /**
     * Show 2FA challenge during login
     */
    public function challenge()
    {
        if (!session('2fa_user_id')) {
            return redirect()->route('login');
        }

        return view('auth.two-factor.challenge');
    }

    /**
     * Verify 2FA code during login
     */
    public function verify(Request $request)
    {
        $request->validate([
            'code' => 'required|string',
        ]);

        $userId = session('2fa_user_id');
        if (!$userId) {
            return redirect()->route('login');
        }

        $user = \App\Models\User::find($userId);
        if (!$user) {
            return redirect()->route('login');
        }

        $code = $request->code;

        // Check if it's a recovery code
        if ($this->isRecoveryCode($user, $code)) {
            $this->useRecoveryCode($user, $code);
            
            Auth::login($user);
            session()->forget('2fa_user_id');
            
            return redirect()->intended(route('dashboard'))
                ->with('warning', 'You used a recovery code. Please generate new ones from your profile.');
        }

        // Verify TOTP code
        $secret = decrypt($user->two_factor_secret);
        $valid = $this->google2fa->verifyKey($secret, $code);

        if (!$valid) {
            return back()->withErrors(['code' => 'Invalid verification code.']);
        }

        // Login successful
        Auth::login($user);
        session()->forget('2fa_user_id');

        return redirect()->intended(route('dashboard'));
    }

    /**
     * Check if code is a recovery code
     */
    private function isRecoveryCode($user, $code): bool
    {
        if (!$user->two_factor_recovery_codes) {
            return false;
        }

        $code = strtoupper(str_replace('-', '', $code));
        
        foreach ($user->two_factor_recovery_codes as $recoveryCode) {
            if (hash_equals($recoveryCode, $code)) {
                return true;
            }
        }

        return false;
    }

    /**
     * Use and remove a recovery code
     */
    private function useRecoveryCode($user, $code): void
    {
        $code = strtoupper(str_replace('-', '', $code));
        $codes = $user->two_factor_recovery_codes;

        $codes = array_filter($codes, function($recoveryCode) use ($code) {
            return !hash_equals($recoveryCode, $code);
        });

        $user->update([
            'two_factor_recovery_codes' => array_values($codes),
        ]);
    }

    /**
     * Regenerate recovery codes
     */
    public function regenerateRecoveryCodes(Request $request)
    {
        $request->validate([
            'password' => 'required',
        ]);

        $user = Auth::user();

        // Verify password
        if (!\Hash::check($request->password, $user->password)) {
            return back()->withErrors(['password' => 'Invalid password.']);
        }

        // Generate new recovery codes
        $recoveryCodes = $user->generateRecoveryCodes();

        $user->update([
            'two_factor_recovery_codes' => $recoveryCodes,
        ]);

        return view('auth.two-factor.recovery-codes', [
            'recoveryCodes' => $recoveryCodes,
            'regenerated' => true,
        ]);
    }
}
