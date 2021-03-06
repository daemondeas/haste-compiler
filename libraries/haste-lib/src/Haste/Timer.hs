{-# LANGUAGE OverloadedStrings #-}
module Haste.Timer (Timer, Interval (..), setTimer, stopTimer) where
import Control.Applicative
import Control.Monad.IO.Class
import Haste.Foreign
import Haste.Events.Core

-- | Timer handle.
data Timer = Timer {
    timerIdentifier :: !Int,
    timerInterval   :: !Interval
  }

-- | Interval and repeat for timers.
data Interval
  = Once !Int   -- ^ Fire once, in n milliseconds.
  | Repeat !Int -- ^ Fire every n milliseconds.

-- | Set a timer.
setTimer :: MonadEvent m
         => Interval -- ^ Milliseconds until timer fires.
         -> m ()     -- ^ Function to call when timer fires.
         -> m Timer  -- ^ Timer handle for interacting with the timer.
setTimer i f = do
    f' <- mkHandler $ const f
    liftIO $ do
      flip Timer i <$> case i of
        Once n   -> timeout n (f' ())
        Repeat n -> interval n (f' ())
  where
    {-# NOINLINE timeout #-}
    timeout :: Int -> IO () -> IO Int
    timeout = ffi "(function(t,f){window.setTimeout(f,t);})"

    {-# NOINLINE interval #-}
    interval :: Int -> IO () -> IO Int
    interval = ffi "(function(t,f){window.setInterval(f,t);})"

-- | Stop a timer.
stopTimer :: MonadIO m => Timer -> m ()
stopTimer (Timer ident (Once _)) = liftIO $ go ident
  where
    {-# NOINLINE go #-}
    go :: Int -> IO ()
    go = ffi "(function(id){window.clearTimeout(id);})"
stopTimer (Timer ident (Repeat _)) = liftIO $ go ident
  where
    {-# NOINLINE go #-}
    go :: Int -> IO ()
    go = ffi "(function(id){window.clearInterval(id);})"
