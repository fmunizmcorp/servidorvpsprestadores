<?php

namespace App\Events;

use App\Models\Site;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class SiteCreated
{
    use Dispatchable, SerializesModels;

    public Site $site;
    public array $options;

    /**
     * Create a new event instance.
     */
    public function __construct(Site $site, array $options = [])
    {
        $this->site = $site;
        $this->options = $options;
    }
}
