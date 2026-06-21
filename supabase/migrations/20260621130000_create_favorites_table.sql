-- Create favorite_rooms table
CREATE TABLE public.favorite_rooms (
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  room_id UUID NOT NULL REFERENCES public.rooms(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, room_id)
);

-- Set up Row Level Security
ALTER TABLE public.favorite_rooms ENABLE ROW LEVEL SECURITY;

-- Policy: Users can see their own favorites
CREATE POLICY "Users can view own favorite rooms"
  ON public.favorite_rooms
  FOR SELECT
  USING (auth.uid() = user_id);

-- Policy: Users can add their own favorites
CREATE POLICY "Users can insert own favorite rooms"
  ON public.favorite_rooms
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own favorites
CREATE POLICY "Users can delete own favorite rooms"
  ON public.favorite_rooms
  FOR DELETE
  USING (auth.uid() = user_id);
