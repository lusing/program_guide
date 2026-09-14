init python:
    if not hasattr(persistent, "seen_endings"):
        persistent.seen_endings = []

label record_ending:
    if ending not in persistent.seen_endings:
        $ persistent.seen_endings.append(ending)
    "已记录结局: [ending]"
    return
