##############################
# PATH Exports & Configuration
##############################
if [ -x "$(command -v colorls)" ]; then
    alias ls="colorls"
    alias la="colorls -al"
fi

# Pyenv
eval "$(pyenv init --path)"

## Kube Editor
export KUBE_EDITOR='micro'

## maven
export PATH=$PATH:/opt/apache-maven/bin

## Postgres
export PATH="/usr/local/opt/postgresql@15/bin:$PATH"



### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/charles.crickard/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


#########
# Aliases
#########
# OVERRIDES
alias g="git"
alias k="kubectl"
alias pip="pip3"
alias kx="kubectx"
alias tf="terraform"

# HELPERS
alias home="cd ~"
alias updir="cd '$OLDPWD'"
alias clip="tr -d '\n' | pbcopy"
alias scratches="cd '~/Library/Application Support/JetBrains/IntelliJIdea2023.2/scratches'"
alias dotfiles="/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"
alias prettyjson='python -m json.tool'

# CONFIG FILES DIRECT
alias zshconfig="micro ~/.zshrc"
alias awsconfig="micro ~/.aws/config"
# alias zshalias="micro $ZSH/custom/aliases.zsh"
# alias zshfunctions="micro $ZSH/custom/functions.zsh"

# APPLICATION DEVELOPMENT
alias push="npm run test && npm run build && git push"
alias scan="npm run test && npm run build"
alias ngtest="ng test --watch"
alias run_client="nvm use && npm i && npm start"
alias run_server="source venv/bin/activate && pip3 install -r requirements.txt --upgrade && export GOOGLE_APPLICATION_CREDENTIALS=\"$PWD/kms_files/decrypted/dev_mip2_service_account.json\" && python3 main.py"
alias server_install="pip install -r requirements.txt --upgrade"
alias activate="source venv/bin/activate"
alias re_npm="rm -rf node_modules/ && nvm use && npm i"
alias pipuninstall='pip freeze | xargs pip uninstall -y'
alias pipinstall='if test -f "requirements_local.txt"; then pipinstall "requirements_local.txt"; else pipinstall "requirements.txt"; fi'
alias codebuild="./codebuild_build.sh -i aws/codebuild/standard:5.0 -b buildspec.yaml -a ./artifacts -c"

# TERRAFORM
alias tfi="terraform init"
alias tftest="terraform init; terraform validate"

# AWS
alias awslogin="_awslogin master; _awslogin dev; _awslogin sit; _awslogin stage; _awslogin prod; _awslogin shared;"

# MISC
alias gurush="easy_ssh cloud_user $1"
alias keycloak="docker run -p 8081:8080 -e KEYCLOAK_ADMIN=admin -e KEYCLOAK_ADMIN_PASSWORD=admin -v keycloak-vol:/var/lib/docker/volumes/keycloak/_data quay.io/keycloak/keycloak:21.1.1 start-dev"

# JUST FOR FUN
alias weather="curl http://wttr.in/"


#############
# Functions #
#############

#### Helpers
function killport {
    echo "Kill port $1"
    pid=$(lsof -i:$1 -t);
    echo $pid
    kill -TERM $pid 2> /dev/null
    kill -KILL $pid 2> /dev/null
}

# Runs postgress locally against minikube
function postgres-dev-client() {
	kubectx minikube
	export POSTGRES_PASSWORD=$(kubectl get secret --namespace default postgresdb-dev-postgresql -o jsonpath="{.data.postgres-password}" | base64 -d);
	kubectl run postgresdb-dev-postgresql-client --rm --tty -i --restart='Never' --namespace default --image docker.io/bitnami/postgresql:15.2.0-debian-11-r16 --env="PGPASSWORD=$POSTGRES_PASSWORD" \
	      --command -- psql --host postgresdb-dev-postgresql -U postgres -d krypti -p 5432
}

# TODO: Move to a docker compose
function keycloak-dev () {
	docker run -p 8081:8080 -e KEYCLOAK_ADMIN=admin -e KEYCLOAK_ADMIN_PASSWORD=admin -v keycloak-vol:/var/lib/docker/volumes/keycloak/_data quay.io/keycloak/keycloak:21.1.1 start-dev

}


#### Kubernes
# Sets current namespace
function kns() {
    kubectl config set-context --current --namespace="$1"
}

# Describes a pod
function kdp() {
    local pod_name
    while read -r pod_name; do
        kubectl describe pod "$pod_name"
    done
}

# executes inside a kubernetes pod that matches the input
function kpsh () {
	echo "Starting exec for ${1}"
	kubectl exec --stdin --tty $1 -- /bin/sh  	
}

# Gets the host of a named ingress
function gethost () {
	HOST=$(kubectl get ingress/$1 -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
	echo $HOST
	echo $HOST | clip
	echo "Coppied to clipboard"
	
}

# runs kubectl get pods. Can optionally pass a filter to look for a specific pod or list of pods that match
function kgp {
    local pod_name=$1
    if [ -z "$pod_name" ]; then
        kubectl get pods
        return 1
    fi

    local pods
    pods=$(kubectl get pods --no-headers -o custom-columns=":metadata.name" | grep -i "$pod_name")
	
    if [ -z "$pods" ]; then
        echo "No matching pods found."
        return 1
    fi

    echo "$pods"
}


function klp {
    local follow=false
    
    local pod_name="$1"
    echo "Looking for pods matching ${pod_name}"

    # Check if the first argument is "--follow"
    if [ "$1" = "--follow" ] || [ "$1" = "-f" ]; then
        echo "Following the logs"
        follow=true
        shift
    fi

    if [ -z "$pod_name" ]; then
        echo "Please provide a pod name or part of it as an argument."
        return 1
    fi

    local matching_pods
    matching_pods=($(kgp "$pod_name"))

    echo $matching_pods

    if [ "${#matching_pods[*]}" -eq 0 ]; then
    	echo "No matching pods found."
        return 1
    fi

    if [ "${#matching_pods[*]}" -eq 1 ]; then
        if [ "$follow" = true ]; then
            kubectl logs -f "${matching_pods}"
        else
            kubectl logs "${matching_pods}"
        fi
        return 0
    fi

    echo "Multiple pods found. Please select a pod:"
    local i=0
    local pod_info
    local options=()

    # Fetch information for all matching pods in one command
    local pod_info_all
    pod_info_all=$(kubectl get pods "${matching_pods[@]}" -o custom-columns="NAME:.metadata.name,READY:.status.containerStatuses[*].ready,RESTARTS:.status.containerStatuses[*].restartCount,IMAGE:.status.containerStatuses[*].image" 2>/dev/null)

    if [ -n "$pod_info_all" ]; then
        while read -r line; do
            # Extract the full image name
            full_image_name=$(echo "$line" | awk '{print $4}')
            
            # Extract and format the image name (name:tag)
            image_name_and_tag=$(echo "$full_image_name" | awk -F'/' '{print $NF}')
            
            # Replace the full image name with the formatted name and tag
            line=$(echo "$line" | sed "s|$full_image_name|$image_name_and_tag|")
            
            # Append the pod_info to the options array
            options+=("$line")

            # Increment the counter
            ((i++))

            # Print the current pod_info
            echo "$i) $line"
        done <<< "$pod_info_all"
    fi

    local selected_pod
    while true; do
        echo "Enter the number of the pod (1-${#matching_pods[*]}): "
        read selected_pod
        if [[ "$selected_pod" =~ ^[0-9]+$ ]] && [ "$selected_pod" -ge 1 ] && [ "$selected_pod" -le "${#matching_pods[*]}" ]; then
            break
        else
            echo "Invalid selection. Please enter a valid number."
        fi
    done

    # Retrieve and display the logs for the selected pod
    if [ "$follow" = true ]; then
        kubectl logs -f "${matching_pods[$((selected_pod-1))]}"
    else
        kubectl logs "${matching_pods[$((selected_pod-1))]}"
    fi
}



# Interactively decodes a kubernetes secret that matches the input
function decode_k8s_secret {
  if [ -z "$1" ]; then
    echo "Please provide the secret name as an argument."
    return 1
  fi

  local secret_data
  secret_data=$(kubectl get secret "$1" -o jsonpath='{.data}')

  if [ -z "$secret_data" ]; then
    echo "Secret not found or no data available."
    return 1
  fi

  local keys
  keys=($(echo "$secret_data" | jq -r 'keys[]'))

  if [ ${#keys[@]} -eq 0 ]; then
    echo "No keys found in the secret data."
    return 1
  fi

  echo "Select a key to decode:"
  select key in "${keys[@]}"; do
    if [ -n "$key" ]; then
      local decoded_value
      decoded_value=$(echo "$secret_data" | jq -r ".[\"$key\"]" | base64 -d)
      echo "Decoded value for $key: $decoded_value"
      break
    else
      echo "Invalid option. Please select a valid key."
    fi
  done
}

function restartdeployment() {
    local deployment_name="$1"
    local replicas="${2:1}"  # Use the second argument or default to 1 if not provided

    kubectl scale deploy "$deployment_name" --replicas=0
    kubectl scale deploy "$deployment_name" --replicas="$replicas"
}

function decodeAwsMessage() {
	aws --profile=$2 sts decode-authorization-message --encoded-message $1
}

# Installs a python version matching the format x.y.z
function pyinstall() {
    local version="$1"
    if [[ "$version" =~ ([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
        major="${BASH_REMATCH[1]}"
        minor="${BASH_REMATCH[2]}"
        patch="${BASH_REMATCH[3]}"
        echo "Major version: $major"
        echo "Minor version: $minor"
        echo "Patch version: $patch"
        # a=${echo $1 | awk 'BEGIN {FS="."}'}
       	# pyenv install -l | grep -e '3.[0-9].[0-9]' | grep -v - | tail -1
    else
        echo "Invalid version format: $version. Please provide a version in the format X.Y.Z."
    fi
}

# execs into a docker container that matches the input
function dockerexec () {
	echo "Starting exec for ${1}"
	docker exec -it $1 /bin/bash
}

_awslogin () {
	PYTHONWARNINGS="ignore" aws-adfs login --profile=$@ --adfs-host=adfs.wgu.edu --no-ssl-verification --session-duration 14400 --no-sspi
}

easy_ssh () {
	echo "ssh ${1}@${2}"
	expect -c "
	spawn ssh ${1}@${2}
	set timeout 5
	expect {
		\"int])?\" { send \"yes\r\"; exp_continue }
	}
	"
	# echo "ssh ${1}@${2}"
	# ssh ${1}@${2}
}

awslocal() {
	profile='sbx'
	while getopts 'p:' OPTION; do
	  case "$OPTION" in
	    p)
	      profile="$OPTARG"
	      echo "The value provided is $OPTARG"
	      ;;
	    ?)
	      echo "script usage: $(basename \$0) [-l] [-h] [-a somevalue]" >&2
	      exit 1
	      ;;
	  esac
	done
	shift "$(($OPTIND -1))"
	
	echo "aws $@ --region us-west-2 --profile $profile --endpoint-url 'http://localhost:4566'"
	aws $@ --region us-west-2 --profile $profile --endpoint-url "http://localhost:4566"
}

awsd () {
	profile='sbx'
	while getopts 'p:' OPTION; do
	  case "$OPTION" in
	    p)
	      profile="$OPTARG"
	      echo "The value provided is $OPTARG"
	      ;;
	    ?)
	      echo "script usage: $(basename \$0) [-l] [-h] [-a somevalue]" >&2
	      exit 1
	      ;;
	  esac
	done
	shift "$(($OPTIND -1))"
	
	echo "aws ${@} --region us-west-2 --profile ${profile}"
	aws $@ --region us-west-2 --profile $profile
}

function awsreset () {
	
	OPWD=$(pwd)

	setopt extendedglob
	cd ~/.aws

	rm -rf ^(pip3|cli|config)

	cd ${OPWD}
}


function update_awslogin() {
	# Clone Command. Replaced with git pull
	git clone git@github.com:WGU-edu/SecOps-AWS-CLI.git
	git pull
	cd SecOps-AWS-CLI
	pip uninstall aws-adfs --yes --quiet
	pip install aws-adfs 
	awsreset_fn
	rm -rf SecOps-AWS-CLI
	
}

function delinstance () {
	echo "Please input the project id:"
	read projectId
	echo "Would you like this to be a dry run?\n1. Yes\n2. No"
	echo "Enter Numerical Value for your choice"
	read dryRun

	if [ $dryRun = "1" ];
	then
		gcloud app instances list --project="$projectId" --format="json" | jq -r ".[] | [.id, .service, .version] | @tsv" <<< "$JSON" | while IFS=$'\t' read -r id service version; do echo gcloud app instances delete "$id" -s "$service" -v "$version" --quiet --project="$projectId"; done;
	else
		gcloud app instances list --project="$projectId" --format="json" | jq -r ".[] | [.id, .service, .version] | @tsv" <<< "$JSON" | while IFS=$'\t' read -r id service version; do gcloud app instances delete "$id" -s "$service" -v "$version" --quiet --project="$projectId"; done;
	fi

}

function genDockerConfig() {
    # Docker registry URL (replace with your actual URL)
    registry_url="nexus.shared.wgu.edu:9443"

    # Prompt the user for their username
    echo -n "Enter the Docker username: "
    read username

    # Prompt the user for their password (and hide the input)
    echo -n "Enter the Docker password: "
    read -s password
    echo

    # Encode the username and password in Base64
    auth_base64=$(echo -n "$username:$password" | base64)

    # Create the Docker config JSON
    docker_config="{\"auths\":{\"$registry_url\":{\"username\":\"$username\",\"password\":\"$password\",\"auth\":\"$auth_base64\"}}}"

    # Save the Docker config JSON to a file
    echo $docker_config > ~/dockerconfig.json

    echo "Docker config JSON file created and saved to ~/dockerconfig.json."

    # Create a Kubernetes secret
    kubectl create secret generic --dry-run=client my-registry-secret \
        --from-file=.dockerconfigjson=dockerconfig.json \
        --type=kubernetes.io/dockerconfigjson -o yaml > secret.yaml

    echo "Docker config secret saved to secret.yaml\n"

    echo "To update the secret to the cluster, please run the following command:"
    echo "kubectl apply -f secret.yaml"
}



############################
# Autocorrect "nocorrect" #
###########################
alias install="nocorrect template"

########################
# PowerLevel10k Config #
########################
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


####################
# Oh My ZSH Config #
####################
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-syntax-highlighting zsh-autosuggestions history npm aws terraform)

source $ZSH/oh-my-zsh.sh
# source $(dirname $(gem which colorls >/dev/null))/tab_complete.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
	export EDITOR='micro'
else
 	export EDITOR='micro'
fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
