$frontendrg = "Frontend-P1-RG"
$LBFrontendNewPrivateIPAddress = "10.0.0.5" #This is the IP address of the frontend load balancer in the new resource group. This is going to be the new green.
$LBFrontendOldPrivateIPAddress = "10.0.0.6" #This is the IP address of the frontend load balancer in the old resource group. 

$frontendappgw = Get-AzureRmApplicationGateway -Name "bgappgw" -ResourceGroupName $frontendrg

$frontendappgw | Set-AzureRmApplicationGatewayBackendAddressPool -Name pool01 -BackendIPAddresses $LBFrontendOldPrivateIPAddress,$LBFrontendNewPrivateIPAddress

Set-AzureRmApplicationGateway -ApplicationGateway $frontendappgw

$frontendappgw = Get-AzureRmApplicationGateway -Name "bgappgw" -ResourceGroupName $frontendrg

$frontendappgw | Set-AzureRmApplicationGatewayBackendAddressPool -Name pool01 -BackendIPAddresses $LBFrontendNewPrivateIPAddress

Set-AzureRmApplicationGateway -ApplicationGateway $frontendappgw