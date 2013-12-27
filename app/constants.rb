WINDOW_WIDTH = 1200
WINDOW_HEIGHT = 900
WIDTH = 640
HEIGHT = 480
WORLD_SIZE = 25000.0
# DEBUG = true
DEBUG = false

STORY = [
  ["It's all gone...                 ( press space )", true],               #0
  ["... and it's been weeks since I touched these controls.", true],
  ["If I'm gonna find anyone, I need to start looking.", true],
  ['Just turn the radio on.          ( press "." )', true],
  ["Wait, this isn't just static! ( tune with ',' and '.' )", true],
  ["There must be someone out there...", true],
  ["...somewhere.", true],
  ["How did you escape, whoever you are? (press <, ^, > )" , false],
  ["There's nobody here...", true],
  ["But there's more on the radio.", true],
  ["If I shut this thing down, I can hear more radio signals.", true],      #10
  ["( press SPACE )", true],
  ["It was nothing, after all - just some old artifact.", true],
  ["...but I know there's more of these.", true],
  ["Maybe she made it to one...  ( tune with ',' and '.' )", false],
  ["This one is empty, too.", true],
  ["I'll just shut it down and clear the radio some more.", true],
  ["( press SPACE )", true],
  ["Each empty artifact is just one less place to look.", true],
  ["Did what happened to me happen here too?", false],
  ["...and did what happened to me, happen to you?", true],                 #20
  ["( press SPACE )", true],                                                  
  ["(tune with ',' and '.' )", false],
  ["Are you out there looking, too? Cause you're not here.", true],
  ["( press SPACE )", true],
  ["Either way, I will keep looking.", true],
  ["I'll always be looking.", false],
  ["There's no one here, either.", true],
  ["( press SPACE )", true],
  ["Everything on this radio is terrible.", true],
  ["It's still better than static, though.", false],                        #30
  ["Dark windows. Yet another vacant artifact.", true],                
  ["( press SPACE )", true],
  ["Am I really, truly, alone?", false],                
  ["I still hope one of these signals is yours.", true],
  ["Are you broadcasting too?", true],
  ["( press SPACE )", true],
  ["There's only a handful of broadcasts left...", false],
  ["Chasing these signals is unbearable;", true],
  ["I still won't stop until there's only static left.", true],
  ["( press SPACE )", true],
  ["But what if I search them all", true],
  ["...and I don't find you?", false],
  ["I've checked this radio so many times now...", true],
  ["I know there's only a few more of these left.", true],
  ["( press SPACE )", true],
  ["Maybe I should just turn this radio off.", true],
  ["...", true],
  ["No, I can't! I'm too close now.", false],
  ["You're not here, but you're somewhere.", true],
  ["I can feel it.", true],
  ["( press SPACE )", true],
  ["...", true],
  ["I can only hear this one last signal.", true],
  ["... ... ... ... ... ...", false],
  ["...and it isn't you.", true],
  ["( press SPACE )", true],
  ["...", true],
  ["It wasn't you.", true],
  ["( turn the radio off with ',' )", false],

]
#radio cues need to reference the state before the one that triggers radio
# i.e. : if state is this, advance to next state which involves the radio
RADIO_CUES = [7,14,19,22,26,30,33,37,42,48,54]
#artifact cues reference the "press space action of each artifact"
ARTIFACT_CUES = [11,17,21,24,28,32,36,40,45,51,56]