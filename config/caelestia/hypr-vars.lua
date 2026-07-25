return {
    -- Don't call system suspend (broken on this FA506NCR + NVIDIA s2idle laptop)
    sleepGestureCmd = "loginctl lock-session",
}
