define e = Character("Eileen")

default emotion = "neutral"

define emotion_label = {
    "happy": "欢快",
    "quiet": "沉静",
    "angry": "愤怒",
    "neutral": "平静",
}

label show_emotion:
    e "当前情绪：[emotion_label[emotion]]。"
    return
