# RepoCleaner
RepoCleaner

The script is expected to count the number of branches available within the GitHub repository where multiple repository names are passed via an input text file and prints the count of branch available and then we are checking the last commit date to understand if the last commit is older than 365 days [1 year] as of current date and will treat them as stale branch. 

We then expect a input from the user [yes/selective]. if yes is inputted, then the deletion API is called and the stale branch which is older than 365 days will get deleted or if selective is choosen, then it gives an additional option to input the branch name to delete else it will go ahead with the next repo available in the text input file.
