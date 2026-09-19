.pragma library

// The patient's side of the conversation printed in Weizenbaum's January 1966
// CACM paper. Nothing of ELIZA's side is stored: the engine answers live, and
// with the DOCTOR script it gives the published replies word for word.
var INPUTS = [
  "Men are all alike.",
  "They're always bugging us about something or other.",
  "Well, my boyfriend made me come here.",
  "He says I'm depressed much of the time.",
  "It's true. I am unhappy.",
  "I need some help, that much seems certain.",
  "Perhaps I could learn to get along with my mother.",
  "My mother takes care of me.",
  "My father.",
  "You are like my father in some ways.",
  "You are not very aggressive but I think you don't want me to notice that.",
  "You don't argue with me.",
  "You are afraid of me.",
  "My father is afraid of everybody.",
  "Bullies."
]
// Typing beat for the patient, in milliseconds per character: a person at a
// keyboard, a little faster than the teletype answers.
var KEY_MS = 70
// Pause after ELIZA finishes before the patient starts typing again.
var THINK_MS = 1400
