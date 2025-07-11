from supabase.client import create_client, Client
import os
from typing import Optional

class SupabaseClient:
    def __init__(self):
        self.supabase: Optional[Client] = None

    def init_app(self, app):
        self.supabase = create_client(
            app.config['SUPABASE_URL'],
            app.config['SUPABASE_KEY']
        )

supabase_client = SupabaseClient() 