import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  'https://your-project.supabase.co',      // Replace this
  'your-anon-api-key'                      // Replace this
);

export default async function handler(req, res) {
  const { data, error } = await supabase.from('messages').select('*');
  if (error) {
    return res.status(500).json({ error: error.message });
  }
  res.status(200).json(data);
}
