This tutorial is to assist you in setting up your coding environment if you do not have them already.

# No-Installation Guide (Google Colab)
We are in 2025. Technology is advanced. AI is taking our jobs.   
You do not need to go through lengthy installation tutorials.  
You can just use Google Colab. It already has the necessary libraries installed.   
It has a built-in AI to generate text and code.     

**Disadvantages:** it may be slower, and you'll be consuming your drive capacity.  

How to use colab: just go to Google drive -> New -> Other -> Google Colaboratory

To use the class materials on Google Colab, upload them to your drive manually, or clone this Github Repository to a folder in your computer which is automatically synchronized to your Google drive.

**R:** To run R in Colab instead of Python, click Runtime from the menu on the top, and select R in the popup named Runtime Type

## Python versus R?
Both Python and R are supported in this course, and the lectures will be nearly evenly split between the two.   
The Fundamentals of Data Analysis lecture (first half of Day 2) will include worksheets in both languages.     
However, we recommend Python — it has stronger support for tasks such as machine learning, natural language processing, and general-purpose programming.      
It’s also more commonly used in interdisciplinary and production-level data science projects.      
That said, if you’re already comfortable with R and don’t want to switch, that’s completely fine. You’ll be able to follow along with R throughout the summer school.   


# Tools Installation
You need to install 
1) a programming language(s)
2) a coding environment to facilitate coding ("**IDE**")
3) a software to collaborate with others and track changes (named "Version Control System", VCS)

# Installing Python
Install Anaconda, which includes Python and fundamental data science libraries (i.e., prewritten code) like pandas.   
https://www.anaconda.com/download.   
(Install anaconda, not miniconda).   

__Optional__: Conda helps you create isolated __environments__ so that the libraries you install will not create conflicts.  
Unless you are going to do Data Science as full-time job, I doubt you will have this problem.  
However, for safety, especially if you are going to install new libraries, you should create a new environment and use it in your projects (or create a new environment for each project).   
You can do this on your IDE, in Anaconda Navigator or by the command:  
`conda create -y -n sicss python=3.11 scipy pandas numpy matplotlib=3.7.2.`    
`conda activate sicss.`


__Optional__: If you prefer running commands from powershell/terminal to using an ide or the Anaconda Navigator.  
You must add conda to your "Path" (so that your computer will recognize the command "conda").  
__Windows:__ In the download options, choose "Add Anaconda3 to my PATH environment variable".  
__Linux:__ go to Downloads or wherever the Anaconda installer is and run.  
`bash ./Anaconda3-2024.06-1-Linux-x86_64.sh -b -p $HOME/Anaconda3. `  
__Mac:__ conda should already be in your path. If you didn't allow the installer to run conda init or conda command does not work for some reason you can do:  
`echo 'export PATH="$HOME/anaconda3/bin:$PATH"' >> ~/.zshrc`   
`source ~/.zshrc`   
Or, reinstall.  


# Installing R
Download R from here and follow the installer https://cran.r-project.org

__Optional__: If you installed Anaconda and able to use the "conda" command you can install R like this:       
`conda create -n sicss_r  r-essentials r-base`     
`conda activate sicss_r`    
This will first create an environment named sicss_r and then install R and the packages

# Installing a Coding Environment, an IDE.
Best way to do data analysis is using a Jupyter Notebook where you can mix markdown with code, print output and show your work in one place.    
You can run Jupyter Notebook on a browser (by launching on Anaconda Navigator).       
However, we recommend installing an IDE and running Jupyter Notebook inside it for a smoother experience.  

We recommend **Cursor**:   
Cursor: https://www.cursor.com (**Pro version is free for students!!**).  

Alternatives: [Windsurf](https://windsurf.com), [VS Code](https://code.visualstudio.com), [PyCharm](https://www.jetbrains.com/pycharm/) (Weak AI Support)


**R:** Cursor supports R but it requires a bit of installation.   
First, install "R Extension for Visual Studio Code" https://open-vsx.org/extension/reditorsupport/r.   
 In R, run the following to install the necessary packages:
   ```r
   install.packages("languageserver")   # Enables linting and completion
   install.packages("IRkernel")         # Enables R in Jupyter Notebooks
   ```
On Cursor, choose an environment with R installed when running files or running a jupyter notebook  
To create an environment with R installed, run the command and activate it.   
`conda create -n sicss_r  r-essentials r-base`                 
`conda activate sicss_r`

**R Studio (Optional):** Before the AI revolution, SICSS recommended R Studio to run R. (They have not updated yet).    
We recommend Cursor as R Studio does not have any AI features (yet). However, if you have problems with Cursor or want to go traditional, you can use R Studio.   
https://posit.co/downloads/ (Click on download RSTUDIO).     

# Installing a Collaboration Software ("Version Control System")
Multiple people may work on the same code. To avoid conflicts, software engineers use a "version control system".  
This will be handy when we update the SICSS materials. You will be able to download new materials to the same folder **without overwriting the notebooks you have edited/worked on.**  
You may also need this when you do your group project.  
If you have already been using Github by the command line, that's great.   
If not, Github Desktop is the easiest way to use Github https://github.com/apps/desktop.      
Of course, do not forget to register if you have not.  
  
Git has the following actions:  
**Clone a repository:** Download a repository to a folder. The difference from a regular download is that you can download the updates directly to the existing folder __if there is no conflict__.  
**Add**: Stage the files you've changed so that Git knows you want to include them in your next snapshot.    
**Commit**: Save a snapshot of the staged changes to your local repository.   
**Push**: Upload your local commits (snapshots) to GitHub (the remote repository).  
You have commands (clone, add, commit, push) for all these actions, but Github Desktop handles them for you.  

# Learning R:
To learn R, the main SICSS organization has a bootcamp you can follow:
https://sicss.io/boot_camp/

# Learning Python:
Follow the .ipynb (Jupyter Notebook) files in this repo in alphanumeric order.     
Files starting with `0_` are beginner-friendly.  
The `challenge/` folder contains a data analysis challenge to test your CSS skills.  
🛠 Note: We’re still uploading the materials.   

# Markdown:
Markdown is very easy and very effective.  
Follow this tutorial: https://www.markdowntutorial.com 


