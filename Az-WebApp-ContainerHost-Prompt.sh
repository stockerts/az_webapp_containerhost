#!/bin/bash

# Define color codes
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
RESET='\033[0m'

while true; do
    # List available subscriptions
    echo -e "Fetching available subscriptions..."
    Subscriptions=$(az account list --query "[].{Name:name, ID:id}" -o tsv)
    
    if [[ -z "$Subscriptions" ]]; then
        echo ""
        echo -e "${YELLOW}No subscriptions found. Please ensure you are logged in to Azure.${RESET}"
        exit 1
    fi

    # Display subscriptions with numbers
    echo ""
    echo -e "${YELLOW}Available Subscriptions:${RESET}"
    IFS=$'\n'  # Set IFS to handle multi-line input correctly
    SubscriptionArray=()
    i=1
    for Subscription in $Subscriptions; do
        Name=$(echo "$Subscription" | cut -f1)
        ID=$(echo "$Subscription" | cut -f2)
        echo -e "[$i] ${YELLOW}Name:${RESET} $Name ${YELLOW}ID:${RESET} $ID"
        SubscriptionArray+=("$ID")
        ((i++))
    done

    # Prompt user to select a subscription
    echo ""
    read -p "$(echo -e ${YELLOW}Enter the number of your desired subscription: ${RESET})" Selection

    if [[ "$Selection" =~ ^[0-9]+$ && "$Selection" -ge 1 && "$Selection" -le "${#SubscriptionArray[@]}" ]]; then
        Subscription="${SubscriptionArray[$((Selection-1))]}"
        echo -e "${YELLOW}Selected Subscription ID:${RESET} $Subscription"
    else
        echo -e "${YELLOW}Invalid selection. Please try again.${RESET}"
        continue
    fi

        az account set --subscription "$Subscription" && \

    # Prompt for app name
    echo ""
    read -p "$(echo -e ${YELLOW}Name your app [e.g., yourname-appname]: ${RESET})" AppBaseName

    # Generate names based on app name
    ResourceGroupName="${AppBaseName}-rsg"
    AppServicePlanName="${AppBaseName}-asp"
    WebAppName="${AppBaseName}-app"

    # Allow users to override default names
    echo ""
    echo -e "${YELLOW}Generated Web App name:${RESET} $WebAppName"
    while true; do
        read -p "$(echo -e ${YELLOW}Would you like to use this name? [Y/N]: ${RESET})" ConfirmWebApp
        if [[ "$ConfirmWebApp" == "Y" || "$ConfirmWebApp" == "y" ]]; then
            break
        elif [[ "$ConfirmWebApp" == "N" || "$ConfirmWebApp" == "n" ]]; then
            read -p "$(echo -e ${YELLOW}Enter custom Web App name [e.g., yourname-appname-app]: ${RESET})" WebAppName
            break
        else
            echo -e "${RED}Please enter 'Y' or 'N'.${RESET}"
        fi
    done

    # Domain check section
    check_domain_availability() {
        echo ""
        echo "Domain Availability check..."
        Response=$(curl -s -o /dev/null -w "%{http_code}" "$WebAppName.azurewebsites.net")

        if [[ -z "$Response" || ! "$Response" =~ ^[2-5][0-9]{2}$ ]]; then
            echo -e "${GREEN}The domain $WebAppName.azurewebsites.net appears to be available! ${RESET}"
            return 0
        else
            echo -e "${RED}The domain $WebAppName.azurewebsites.net is not available. HTTP response code: $Response. ${RESET}"
            return 1
        fi
    }

    # Continuously prompt for domain name until available
    while true; do
        if check_domain_availability; then
            break
        fi

        # Prompt for changing the domain name with input validation
        while true; do
            read -p "$(echo -e ${YELLOW}The domain is not available. Would you like to change the name? [Y/N]: ${RESET})" ChangeName
            if [[ "$ChangeName" == "Y" || "$ChangeName" == "y" ]]; then
                read -p "$(echo -e ${YELLOW}Enter custom Web App name [e.g., yourname-appname-app]: ${RESET})" WebAppName
                break
            elif [[ "$ChangeName" == "N" || "$ChangeName" == "n" ]]; then
                echo -e "${YELLOW}Proceeding with the current App Name...${RESET}"
                break
            else
                echo -e "${RED}Please enter 'Y' or 'N'.${RESET}"
            fi
        done
    done


    # Resource Group Section
    echo ""
    echo -e "${YELLOW}Generated Resource Group name:${RESET} $ResourceGroupName"

    # Prompt for confirmation with input validation
    while true; do
        read -p "$(echo -e ${YELLOW}Would you like to use this name? [Y/N]: ${RESET})" ConfirmRsg
        if [[ "$ConfirmRsg" == "Y" || "$ConfirmRsg" == "y" || "$ConfirmRsg" == "N" || "$ConfirmRsg" == "n" ]]; then
            break
        else
            echo -e "${RED}Please enter 'Y' or 'N'.${RESET}"
        fi
    done

    if [[ "$ConfirmRsg" != "Y" && "$ConfirmRsg" != "y" ]]; then
        read -p "$(echo -e ${YELLOW}Enter custom Resource Group name [e.g., yourname-appname-rsg]: ${RESET})" ResourceGroupName
    fi

    # App Service Plan Section
    echo ""
    echo -e "${YELLOW}Generated App Service Plan name:${RESET} $AppServicePlanName"

    # Prompt for confirmation with input validation
    while true; do
        read -p "$(echo -e ${YELLOW}Would you like to use this name? [Y/N]: ${RESET})" ConfirmAsp
        if [[ "$ConfirmAsp" == "Y" || "$ConfirmAsp" == "y" || "$ConfirmAsp" == "N" || "$ConfirmAsp" == "n" ]]; then
            break
        else
            echo -e "${RED}Please enter 'Y' or 'N'.${RESET}"
        fi
    done

    if [[ "$ConfirmAsp" != "Y" && "$ConfirmAsp" != "y" ]]; then
        read -p "$(echo -e ${YELLOW}Enter custom App Service Plan name [e.g., yourname-appname-asp]: ${RESET})" AppServicePlanName
    fi

    # Display location options
    echo ""
    echo -e "${YELLOW}Available Locations:${RESET}"
    LocationOptions=("eastus2" "centralus" "westus2" "Enter your own")
    for i in "${!LocationOptions[@]}"; do
        echo -e "[$((i + 1))] ${LocationOptions[$i]}"
    done

    # Prompt user to select a location
    echo ""
    read -p "$(echo -e ${YELLOW}Select a location or enter your own [number]: ${RESET})" LocationSelection

    if [[ "$LocationSelection" =~ ^[0-9]+$ && "$LocationSelection" -ge 1 && "$LocationSelection" -le "${#LocationOptions[@]}" ]]; then
        if [[ "$LocationSelection" -eq "${#LocationOptions[@]}" ]]; then
            read -p "$(echo -e ${YELLOW}Enter your custom location: ${RESET})" Location
        else
            Location="${LocationOptions[$((LocationSelection - 1))]}"
        fi
        echo -e "${YELLOW}Selected Location:${RESET} $Location"
    else
        echo -e "${YELLOW}Invalid selection. Please try again.${RESET}"
        continue
    fi

    # Display SKU options
    echo ""
    echo -e "${YELLOW}Available SKUs:${RESET}"
    echo -e "${YELLOW}The SKU ${RESET}F1 (FREE) ${YELLOW}is recommended${RESET}"
    SkuOptions=("F1" "B1" "B2" "Enter your own")
    for i in "${!SkuOptions[@]}"; do
        echo -e "[$((i + 1))] ${SkuOptions[$i]}"
    done

    # Prompt user to select a SKU
    echo ""
    read -p "$(echo -e ${YELLOW}Select a SKU or enter your own [number]: ${RESET})" SkuSelection

    if [[ "$SkuSelection" =~ ^[0-9]+$ && "$SkuSelection" -ge 1 && "$SkuSelection" -le "${#SkuOptions[@]}" ]]; then
        if [[ "$SkuSelection" -eq "${#SkuOptions[@]}" ]]; then
            read -p "$(echo -e ${YELLOW}Enter your custom SKU: ${RESET})" Sku
        else
            Sku="${SkuOptions[$((SkuSelection - 1))]}"
        fi
        echo -e "${YELLOW}Selected SKU:${RESET} $Sku"
    else
        echo -e "${YELLOW}Invalid selection. Please try again.${RESET}"
        continue
    fi

    # Display container image options
    echo ""
    echo -e "${YELLOW}Available Container Images:${RESET}"
    ContainerImageOptions=("index.docker.io/stockdemo/demoapp:latest" "index.docker.io/bkimminich/juice-shop:latest" "index.docker.io/stockdemo/demobankapi:latest" "Enter your own")
    for i in "${!ContainerImageOptions[@]}"; do
        echo -e "[$((i + 1))] ${ContainerImageOptions[$i]}"
    done

    # Prompt user to select a container image
    echo ""
    read -p "$(echo -e ${YELLOW}Select a container image or enter your own [number]: ${RESET})" ContainerImageSelection

    if [[ "$ContainerImageSelection" =~ ^[0-9]+$ && "$ContainerImageSelection" -ge 1 && "$ContainerImageSelection" -le "${#ContainerImageOptions[@]}" ]]; then
        if [[ "$ContainerImageSelection" -eq "${#ContainerImageOptions[@]}" ]]; then
            read -p "$(echo -e ${YELLOW}Enter your custom container image: ${RESET})" ContainerImage
        else
            ContainerImage="${ContainerImageOptions[$((ContainerImageSelection - 1))]}"
        fi
        echo -e "${YELLOW}Selected Container Image:${RESET} $ContainerImage"
    else
        echo -e "${YELLOW}Invalid selection. Please try again.${RESET}"
        continue
    fi

    # Prompt for tags
    echo ""
    read -p "$(echo -e ${YELLOW}Enter your Email: ${RESET})" Email
    Email=${Email:-<email>}  # Default to <email> if empty
    Tags=("owner=$Email")

    # Display entered values for confirmation
    echo ""
    echo -e "${YELLOW}Please confirm the following values:${RESET}"
    echo -e "${YELLOW}Subscription:${RESET} $Subscription"
    echo -e "${YELLOW}Resource Group:${RESET} $ResourceGroupName"
    echo -e "${YELLOW}App Service Plan:${RESET} $AppServicePlanName"
    echo -e "${YELLOW}Web App:${RESET} $WebAppName"
    echo -e "${YELLOW}Location:${RESET} $Location"
    echo -e "${YELLOW}SKU:${RESET} $Sku"
    echo -e "${YELLOW}Container Image:${RESET} $ContainerImage"
    echo -e "${YELLOW}Tags:${RESET} ${Tags[@]}"
    echo ""

    # Ask for confirmation
    read -p "$(echo -e ${YELLOW}Are these values correct? [Y/N]: ${RESET})" Confirm
    if [[ "$Confirm" == "Y" || "$Confirm" == "y" ]]; then
        # Setting desired Azure Subscription
        az account set --subscription "$Subscription" && \

        # Create Resource Group
        echo ""
        echo "Creating Resource Group $ResourceGroupName..." && \

        az group create --name "$ResourceGroupName" \
                        --location "$Location" \
                        --tags "${Tags[@]}" &>/dev/null

        if [ $? -eq 0 ]; then
            echo "Resource Group $ResourceGroupName has been created."
        else
            echo "Error: Failed to create Resource Group $ResourceGroupName. Please check the provided parameters and try again."
        fi

        # Create App Service Plan
        echo ""
        echo "Creating App Service Plan $AppServicePlanName..." && \

        az appservice plan create --name "$AppServicePlanName" \
                                  --resource-group "$ResourceGroupName" \
                                  --location "$Location" \
                                  --sku "$Sku" \
                                  --is-linux \
                                  --tags "${Tags[@]}" &>/dev/null

        if [ $? -eq 0 ]; then
            echo "App Service Plan $AppServicePlanName has been created." 
                else
            echo "Error: Failed to create App Service Plan $AppServicePlanName. Please check the provided parameters and try again."
        fi

        # Create Web App
        echo ""
        echo "Creating Web App $WebAppName..." && \

        az webapp create --resource-group "$ResourceGroupName" \
                         --plan "$AppServicePlanName" \
                         --name "$WebAppName" \
                         --container-image-name "$ContainerImage" \
                         --tags "${Tags[@]}" &>/dev/null

        if [ $? -eq 0 ]; then
            echo "WebApp $WebAppName has been created."
        else
            echo "Error: Failed to create WebApp $WebAppName. Please check the provided parameters and try again."
        fi

        WebAppDetails=$(az webapp show --name "$WebAppName" --resource-group "$ResourceGroupName" 2>/dev/null)

        if [[ -n "$WebAppDetails" ]]; then
            echo -e "\nDetails for WebApp $WebAppName:"
            echo "$WebAppDetails"
            echo ""
            echo -e "${YELLOW}Your website will take a few minutes to become available:${RESET} $WebAppName.azurewebsites.net"
            echo ""
        else
            echo "Failed to retrieve details for WebApp $WebAppName."
        fi

        # Exit the loop after successful execution
        break
    else
        echo -e "${YELLOW}Please re-enter the values.${RESET}"
        echo ""
    fi
done