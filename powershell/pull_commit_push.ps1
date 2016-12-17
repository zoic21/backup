function Pause ($Message="Appuyez sur une touche pour quitter..."){
	 Write-Host -NoNewLine $Message
	 $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
	 Write-Host ""
}
cd ../..
function pull(){
	$list = dir -Directory -Name
	foreach ($line in $list)
	{
		echo "***********Pull $line *********************"
		cd $line
		git pull
		cd ..
	}
}

function commit_push(){
	$message = Read-Host 'What is your commit message?'
	echo "Commit message is $message"
	$list = dir -Directory -Name
	foreach ($line in $list)
	{
		echo "***********Commit and push for $line *********************"
		cd $line
		echo "Pull..."
		git pull
		echo "Commit..."
		git add .
		git commit -a -m $message
		echo "Push..."
		git push
		cd ..
	}
}


$title = "Pull or push"
$message = "Do you want to pull or push ?"

$yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Pull", `
    "Pull from git"

$no = New-Object System.Management.Automation.Host.ChoiceDescription "&Commit and Push", `
    "Commit and push to git"

$options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)

$result = $host.ui.PromptForChoice($title, $message, $options, 0) 

switch ($result){
	0 {"You selected pull."
		pull
	}
	1 {"You selected commit and push."
		commit_push
	}
}