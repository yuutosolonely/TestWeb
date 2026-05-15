<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // When SMTP credentials are set but MAIL_MAILER was left as "log", still send real mail.
        if (
            config('mail.default') === 'log'
            && filled(env('MAIL_HOST'))
            && filled(env('MAIL_USERNAME'))
            && filled(env('MAIL_PASSWORD'))
        ) {
            config(['mail.default' => 'smtp']);
        }
    }
}
