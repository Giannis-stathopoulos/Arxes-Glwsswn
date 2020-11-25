%{
  /* libs*/
  #include <stdio.h>
  #include <stdlib.h>
  #include <string.h>
  #include <ctype.h>

  /*Flex and bison*/
  FILE *yyin;
  extern int yylineno;
  void yyerror (char *s);
  int yylex();

  /*User functions*/
  void checkCreatedAt(char* createdAt);
  void checkRequirements(int textField, int idStrField, int createdAtField ,int retweetTextField, int retweetUserField, int truncatedField ,int d_t_rField);
  int checkUser(int idField, int nameField, int screenNameField, int locationField);
  void checkTweetText(char* text);

  /*Error handling*/
  int errorArrayEnd = 0;
  char *error[20] = {NULL};
  int errorLineno[20] = {0};
  char *strUnique[50];
  char *strings;

  /* Required fields counters (1st part)*/
  int userID[20];
  int endOfArray=1;
  int endOfArray1=1;
  int textField = 0;
  int idStrField = 0;
  int createdAtField = 0;
  int idField = 0;
  int nameField = 0;
  int screenNameField = 0;
  int locationField = 0;

  /* Required fields counters (2nd part)*/
  int retweetTextField = 0;
  int retweetUserField = 0;
  int tweetTextField = 0;
  int tweetUserField = 0;
  int truncatedField = 0;
  int d_t_rField = 0;
  int truncated = 0;
  int componentToCheck = 0;
  char* originalText;
  char* originalName;
  char* fullTextVal;
  char* fullTextValDup;
  char* tok;


%}
%union {
  int intval;
  double val;
  char* str;
}
%start            JSON
%token            null CREATED_AT
%left             O_BEGIN O_END A_BEGIN A_END
%left             COMMA
%left             COLON
%token            <intval> NUMBER true false TRUNCATED
%token            <str> STRING TEXT_INIT USER_INIT ID_STR RETWEET TWEET D_T_R 
%token            <str> EXT_TWEET FULL_TEXT ENTITIES HASHTAGS INDICES
%%
JSON: O_BEGIN O_END
    | O_BEGIN MEMBERS O_END
    ;

MEMBERS: PAIR
       | PAIR COMMA MEMBERS
       ;

PAIR: STRING COLON VALUE 
    | ENTITIES COLON VALUE
    | HASHTAGS COLON VALUE
    | TEXT_INIT COLON STRING{
      if(strlen($3) <= 140){
        originalText = $3;
        textField++;
      }else{
        error[errorArrayEnd] = "\ntext field is supposed to be less or equal to 140 characters";
        errorLineno[errorArrayEnd] = yylineno;
        errorArrayEnd++;
      }
    }

    |ID_STR COLON STRING{
    int isDigitCounter = 0;
    for(int i = 0; i < strlen($3); i++){
      if($3[i] == *"\"")
        continue;
      if(isdigit($3[i]))
        isDigitCounter++;

    }

    if(isDigitCounter == (strlen($3) - 2)){         /*adjusting for the double quotes the string is supposed to have*/   
      
      int uniqueExist=0;
      strUnique[0] = malloc(strlen($3)+1);
      strings = (char*)malloc(strlen($3)+1);
      strcpy(strings , $3);
      for(int i = 0; i < endOfArray1; i++){   
              if( !strcmp(strUnique[i], strings) ){
                uniqueExist=1;
                error[errorArrayEnd] = "\nDuplicate id_str fields\n";
                errorLineno[errorArrayEnd] = yylineno;
                errorArrayEnd++;
              }
        }
        if(uniqueExist==0){
          strUnique[endOfArray1]=$3;
          endOfArray1++;
        }
      idStrField++;
    }else if(isDigitCounter == 0){
      error[errorArrayEnd] = "\nid_str expected alphanumerical integer, string given\n";
      errorLineno[errorArrayEnd] = yylineno;
      errorArrayEnd++;
    }else{
      error[errorArrayEnd] = "\nmid_str field contains characters\n";
      errorLineno[errorArrayEnd] = yylineno;
      errorArrayEnd++;
    }
    }

    |CREATED_AT COLON STRING{
      checkCreatedAt($3);
      createdAtField++; 
    }

    |USER_INIT COLON O_BEGIN USER_REQUIRED_VALUES O_END

    |RETWEET COLON O_BEGIN RT_REQUIRED_VALUES O_END

    |TWEET COLON O_BEGIN T_REQUIRED_VALUES O_END

    |EXT_TWEET COLON O_BEGIN EXT_TWEET_REQUIRED_VALUES O_END

    |TRUNCATED COLON true {
      truncatedField++;
      truncated = 1;
    }

    |TRUNCATED COLON false {
      truncatedField++;
      truncated = 0;
    }

    |D_T_R COLON A_BEGIN NUMBER COMMA NUMBER A_END {
      d_t_rField++;
      if(($4 < 0 || $6 > 140)){
        error[errorArrayEnd] = "\ndisplay_text_range after truncated true array can't be <0 || >140\n";
        errorLineno[errorArrayEnd] = yylineno;
        errorArrayEnd++;
      }
    }
    ;

USER_REQUIRED_VALUES: USER_REQUIRED_VALUE
               |USER_REQUIRED_VALUE COMMA USER_REQUIRED_VALUES
               ;

RT_REQUIRED_VALUES: RT_REQUIRED_VALUE
               |RT_REQUIRED_VALUE COMMA RT_REQUIRED_VALUES
               ;

T_REQUIRED_VALUES: T_REQUIRED_VALUE
               |T_REQUIRED_VALUE COMMA T_REQUIRED_VALUES
               ;

EXT_TWEET_REQUIRED_VALUES: EXT_TWEET_REQUIRED_VALUE
                        | EXT_TWEET_REQUIRED_VALUE COMMA EXT_TWEET_REQUIRED_VALUES
                        ;

USER_REQUIRED_VALUE: STRING COLON NUMBER{
    if(!strcmp($1,"\"id\"") && $3 >= 0){
      userID[endOfArray] = $3;
      for(int i = 0; i < endOfArray; i++){
        if(i==endOfArray){
          continue;
        }
          if(userID[i] == userID[endOfArray]){
            error[errorArrayEnd] = "\nDuplicate ids\n";
            errorLineno[errorArrayEnd] = yylineno;
            errorArrayEnd++;
        }
      } 
      endOfArray++;
      idField++;
    }
  }

  |STRING COLON STRING
  {
    if(!strcmp($1,"\"name\"")){
      nameField++;
    }
    if(!strcmp($1,"\"screen_name\"")){
      originalName = $3;
      screenNameField++;
    }
    if(!strcmp($1,"\"location\"")){
      locationField++;
    }
  }
  ;
  RT_REQUIRED_VALUE: TEXT_INIT COLON STRING{
    if(!strcmp($3,originalText)){
      retweetTextField++;
    }else{
      error[errorArrayEnd] = "\nRetweet_status text is not the same as the original text\n";
      errorLineno[errorArrayEnd] = yylineno;
      errorArrayEnd++;
    }
  }
  | USER_INIT COLON TWEET_USER {
    retweetUserField++;
  }
  ;

  T_REQUIRED_VALUE: TEXT_INIT COLON STRING{
    tweetTextField++;
    checkTweetText($3);
  }
  | USER_INIT COLON TWEET_USER{
    tweetUserField++;
  }
  ;

  EXT_TWEET_REQUIRED_VALUE: FULL_TEXT COLON STRING {
    fullTextVal = $3;
    //strip double quotes 
    fullTextVal++;
    fullTextVal[strlen(fullTextVal) -1] = 0;
    fullTextValDup = strdup(fullTextVal);
  }
  |D_T_R COLON A_BEGIN NUMBER COMMA NUMBER A_END {
    
    if( $4 != 0 || $6 != strlen(fullTextVal)-1 ){
      error[errorArrayEnd] = "\nextended_tweet display_text_range values do not match length of full_text\n";
      errorLineno[errorArrayEnd] = yylineno;
      errorArrayEnd++;
    }

  }
  |ENTITIES COLON O_BEGIN ENTITIES_MEMBERS O_END
  ;
  ENTITIES_MEMBERS: ENTITIES_MEMBER
                  | ENTITIES_MEMBER COMMA ENTITIES_MEMBERS
  ;
  ENTITIES_MEMBER: STRING COLON VALUE
                 | HASHTAGS COLON HASHTAG_ARRAY
  ;
  HASHTAG_ARRAY: A_BEGIN A_END
               | A_BEGIN HASHTAG_ARRAY_ELEMENTS A_END
  ;
  HASHTAG_ARRAY_ELEMENTS: HASHTAG_ARRAY_ELEMENT
                        | HASHTAG_ARRAY_ELEMENT COMMA HASHTAG_ARRAY_ELEMENTS
  ;
  HASHTAG_ARRAY_ELEMENT: O_BEGIN HASHTAG_ARRAY_REQUIRED_ELEMENTS O_END
  ;
  HASHTAG_ARRAY_REQUIRED_ELEMENTS: HASHTAG_ARRAY_REQUIRED_ELEMENT
                                 | HASHTAG_ARRAY_REQUIRED_ELEMENT COMMA HASHTAG_ARRAY_REQUIRED_ELEMENTS
  ;
  HASHTAG_ARRAY_REQUIRED_ELEMENT: TEXT_INIT COLON STRING{
    if(componentToCheck == 0){
      tok = strtok(fullTextValDup,"#");
    }
    componentToCheck++;
    tok = strtok(NULL,"#");

    // strip double quotes from $3
    $3++;
    $3[strlen($3)-1] = 0;
    if(strcmp(tok, $3)){
      error[errorArrayEnd] = "\ntext property of entities->hashtags does not match original text hashtag\n";
      errorLineno[errorArrayEnd] = yylineno;
      errorArrayEnd++;
    }
  }
  |INDICES COLON A_BEGIN NUMBER COMMA NUMBER A_END{
    if(!(fullTextVal[$4] == '#')){
      error[errorArrayEnd] = "\nhashtag indices do not match full text\n";
      errorLineno[errorArrayEnd] = yylineno;
      errorArrayEnd++;
    }
  }
  ;
  TWEET_USER: O_BEGIN STRING COLON STRING O_END {
      if(strcmp($2,"\"screen_name\"")){
        error[errorArrayEnd] = "\nRetweet_status or tweet user has no screen_name property\n";
        errorLineno[errorArrayEnd] = yylineno;
        errorArrayEnd++;
      }
  }
  ;
ARRAY: A_BEGIN A_END
     | A_BEGIN ELEMENTS A_END
     ;

ELEMENTS: VALUE
        | VALUE COMMA ELEMENTS
        ;

VALUE: STRING
     | NUMBER
     | true
     | false
     | ARRAY
     | JSON
     ;
%%
int main ( int argc, char *argv[] ) {

  if(!(argc == 2)){
    printf("Cannot open %d files!\nExiting...\n", (--argc));
    return 1;
  }
  
  yyin = fopen(argv[1],"r");

  if(yyin == NULL)
  {
    printf("Error -> no file '%s'\n",argv[1]);   
    exit(1);             
  }

  yyparse();
  fclose(yyin);

  if(!(error[0] == NULL)){
    printf("\n/----------ERRORS----------/\n\n");
    for(int i = 0; i <= errorArrayEnd-1; i++){
      printf("Error %d at line %d: %s\n", i+1, errorLineno[i], error[i]);
    }
    return 1;
  }

  checkRequirements(textField, idStrField, createdAtField, retweetTextField, retweetUserField,truncatedField,d_t_rField);
  return 0;
}

// Helper function for checking if the datetime in "created_at field is ok"
void checkCreatedAt(char* createdAt){
  
  const char *DAYS[] = {"Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"};
  const char *MONTHS[] = {"Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};

  char* parsed;
  char* components[10];
  int validateComponents[7];

  // Get the first token
  parsed = strtok (createdAt," \",.:");
  components[0] = parsed;
  validateComponents[0] = 0;
  int i = 1;

  //Get the rest of the tokens and put them in the array
  for(int i = 1; i <= 7; i++){
    if(parsed == NULL)
      break;
    else{
      parsed = strtok (NULL, " \",.:");
      validateComponents[i] = 0;
      components[i] = parsed;
    }
  }
  
  //Check if the day belongs in DAYS if not add to the error array
  for(int i = 0; i < 7; i++){
    if(!strcmp(DAYS[i],components[0])){
      validateComponents[0] = 1;
      break;
    }
  }

  //Check if the month belongs in MONTHS if not add to the error array
  for(int i = 0; i < 12; i++){
    if(!strcmp(MONTHS[i],components[1])){
      validateComponents[1] = 1;
      break;
    }
  }

  //Check the hours minutes and seconds
  int hours = atoi(components[3]) >= 0 && atoi(components[3]) < 24;
  int minutes = atoi(components[4]) >= 0 && atoi(components[4]) < 60;
  int seconds = atoi(components[5]) >= 0 && atoi(components[5]) < 60;
  
  if(hours){
    validateComponents[3] = 1;
  }
  if(minutes){
    validateComponents[4] = 1;
  }
  if(seconds){
    validateComponents[5] = 1;
  }

  //Check the date
  if(atoi(components[2]) > 0 && atoi(components[2]) <= 31){
    validateComponents[2] = 1;
    if(!strcmp(MONTHS[1],components[1]) && atoi(components[2]) > 28){
      validateComponents[2] = 0;
    }
  }

  // Check timezone
  if(components[6][0]=='+'){
      parsed = strtok (components[6],"+");
      if (atoi(parsed)<=1400 && atoi(parsed)>=0){
        validateComponents[6] = 1;        
      }
  }else if (components[6][0]=='-'){
      parsed = strtok (components[6],"-");
      if (atoi(parsed)<=1200 && atoi(parsed)>=0){
        validateComponents[6]=1;
      }
  }
  for(int i = 0; i < 7; i++){
    if(!validateComponents[i]){
      error[errorArrayEnd] = "\nCreated_at field invalid timestamp\n";
      errorLineno[errorArrayEnd] = yylineno;
      errorArrayEnd++;
    }
  }
}

// Helper function for checking what mandatory fields are completed
void checkRequirements(int textField, int idStrField, int createdAtField ,int retweetTextField, int retweetUserField, int truncatedField ,int d_t_rField){
  if(textField){
    printf("\ntext field ok!          \n");
  }
  else{
    printf("ERROR:text field missing          \n");
    exit(1);
  }
  if(idStrField){
    printf("id_str field ok!          \n");
  }else{
    printf("ERROR:id_str field missing          \n");
    exit(1);
  }
  if(createdAtField){
    printf("created_at field ok!          \n");
  }else{
    printf("ERROR:created_at field missing          \n");
    exit(1);
  }
  
  int userField = checkUser(idField, nameField, screenNameField, locationField);

  if(userField == 4){
    printf("user field ok!\n");
  }
  else if(userField == 0){
    printf("ERROR:user field missing\n");
    exit(1);
  }
  else{
    printf("user field bad          \n");
    exit(1);
  }

  /*2nd part requirements*/

  if(retweetTextField){
    printf("retweeted_status text field ok!\n");
  }
  else{
    printf("ERROR:retweeted_status text field missing\n");
    exit(1);
  }
  if(retweetUserField){
    printf("retweeted_status user field ok!\n");
  }
  else{
    printf("ERROR:retweeted_status user field missing          \n");
    exit(1);
  }
  if(tweetTextField){
    printf("tweet text field ok!\n");
  }
  else{
    printf("ERROR:tweet text field missing          \n");
    exit(1);
  }
  if(tweetUserField){
    printf("tweet user field ok!\n");
  }
  else{
    printf("ERROR:tweet user field missing          \n");
    exit(1);
  }
  if(truncatedField && d_t_rField){
    printf("truncated field ok!\n");
  }
  else if(truncated && !d_t_rField){
    printf("ERROR:truncated field is true yet there was no display_text_range array\n");
    exit(1);
  }
}

// Helper function for checking the user fields
int checkUser(int idField, int nameField, int screenNameField, int locationField){
  int userChecks = 0;

  if(idField){
    printf("\tuser id field ok!\n");
    userChecks++;
  }
  if(nameField){
    printf("\tuser name field ok!\n");
    userChecks++;
  }
  if(screenNameField){
    printf("\tuser screen name field ok!\n");
    userChecks++;
  }
  if(locationField){
    printf("\tuser location field ok!\n");
    userChecks++;
  }

  return userChecks;
}

void checkTweetText(char* text){
  char* parsed;
  char* components[10];

  // Get the first token
  parsed = strtok (text," \",.:");
  components[0] = parsed;

  //Get the rest of the tokens and put them in the array
  for(int i = 1; i < 3; i++){
    if(parsed == NULL)
      break;
    else{
      parsed = strtok (NULL, " \",.:");
      components[i] = parsed;
    }
  }

  //Check for RT
  if(strcmp(components[0],"RT")){
    error[errorArrayEnd] = "\nTweet text field needs to be of format 'RT @OriginalAuthor OriginalText' and no RT found\n";
    errorLineno[errorArrayEnd] = yylineno;
    errorArrayEnd++;
  }

  // Check for @OriginalAuthor
  components[1]++;
  originalName++;
  originalName[strlen(originalName) - 1] = 0;
  
  if(strcmp(components[1],originalName)){
    error[errorArrayEnd] = "\nTweet text field needs to be of format 'RT @OriginalAuthor OriginalText' and not original author name\n";
    errorLineno[errorArrayEnd] = yylineno;
    errorArrayEnd++;
  }

  // Components 2 needs to be the rest of the text so we don't have to check
}

// Bison function for printing errors
void yyerror(char *s) {
    fprintf(stderr, "LINE %d: %s\n", yylineno, s);
}