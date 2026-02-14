# Data Modelling

I will evnetually want to add auth via Google or Discord, but idk how that works so for now we can just have a simple Users table 

```
Users {
  id: string
  username: string
  email: string
}

Games {
  id: string
  status: "active" | "won" | "abandoned"
  difficulty: "easy" | "normal" | "hard"
  secret: Choice[]
  datetime_started: datetime
  datetime_ended: datetime
}


Guesses {
  id: string
  game_id: string
  timestamp: datetime
  choices: Choice[]
}

```
