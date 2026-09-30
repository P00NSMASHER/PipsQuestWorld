local SchoolConfig = {}

SchoolConfig.StartDelay = 10
SchoolConfig.ClassDuration = 105
SchoolConfig.PassingDuration = 25
SchoolConfig.PointsPerCorrectAnswer = 10

SchoolConfig.Classes = {
    { id = "homeroom", name = "Homeroom", room = "Room 101" },
    { id = "math", name = "Math", room = "Room 102" },
    { id = "science", name = "Science", room = "Room 103" },
    { id = "english", name = "English", room = "Room 104" },
    { id = "art", name = "Art", room = "Room 105" },
}

SchoolConfig.Questions = {
    homeroom = {
        { prompt = "Which choice shows good classroom teamwork?", choices = {"Ignore everyone", "Take turns and listen", "Hide the supplies", "Leave the room"}, correct = 2 },
        { prompt = "What should you do first when class begins?", choices = {"Check the class directions", "Run outside", "Turn off another player's screen", "Skip the activity"}, correct = 1 },
    },
    math = {
        { prompt = "What is 7 + 8?", choices = {"13", "14", "15", "16"}, correct = 3 },
        { prompt = "Which number is even?", choices = {"11", "13", "18", "21"}, correct = 3 },
        { prompt = "What is 5 × 4?", choices = {"9", "15", "20", "25"}, correct = 3 },
    },
    science = {
        { prompt = "Which object is a source of light?", choices = {"Moon", "Mirror", "Sun", "Book"}, correct = 3 },
        { prompt = "Water becomes ice when it...", choices = {"freezes", "melts", "evaporates", "boils"}, correct = 1 },
        { prompt = "Plants use roots mainly to...", choices = {"hear sounds", "absorb water", "make shadows", "move around"}, correct = 2 },
    },
    english = {
        { prompt = "Which word is a noun?", choices = {"quickly", "school", "bright", "jump"}, correct = 2 },
        { prompt = "Which sentence ends with a question mark?", choices = {"I like art.", "Please sit down.", "Where is my book?", "What a fun day!"}, correct = 3 },
        { prompt = "Which word is a verb?", choices = {"desk", "blue", "write", "quiet"}, correct = 3 },
    },
    art = {
        { prompt = "Red and blue combine to make...", choices = {"green", "orange", "purple", "yellow"}, correct = 3 },
        { prompt = "A repeated decorative design is called a...", choices = {"pattern", "fraction", "planet", "chapter"}, correct = 1 },
    },
}

return SchoolConfig
