Optional narration
==================
Spoken narration is optional; the written instructions are always shown.
For step N of a programme, Calm Garden plays (if it exists):

  assets/narration/<language>/<programme>_<N>.ogg   (or .mp3 / .wav)

Languages: en, he (any language with a file in assets/lang).
Programmes: pmr, bodyscan, breath_aware, place, bedtime, break5, moments.
Example: assets/narration/he/pmr_3.ogg is step 3 of muscle relaxation in Hebrew.
The step waits until its narration has finished before moving on.
No online text-to-speech is used.
