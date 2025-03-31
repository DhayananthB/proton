# `pip3 install assemblyai` (macOS)
# `pip install assemblyai` (Windows)

import assemblyai as aai

aai.settings.api_key = "329420123ba94230bff671bc127f96a7"
transcriber = aai.Transcriber()

transcript = transcriber.transcribe("https://assembly.ai/news.mp4")
# transcript = transcriber.transcribe("./my-local-audio-file.wav")

print(transcript.text)