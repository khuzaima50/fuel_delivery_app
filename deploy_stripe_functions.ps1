# FuelDirect - Supabase Stripe Functions Deployment Script
# 
# PREREQUISITES:
#   1. Get your Supabase Personal Access Token from:
#      https://supabase.com/dashboard/account/tokens
#   2. Run this script in PowerShell:
#      .\deploy_stripe_functions.ps1 -Token "sbp_xxxxxxxxxxxxx"

param(
    [Parameter(Mandatory=$true)]
    [string]$Token
)

$supabase = "$env:USERPROFILE\AppData\Local\supabase\supabase.exe"
$projectRef = "fsxiioldnxdzidcunmma"
$projectRoot = $PSScriptRoot

Write-Host "====================================" -ForegroundColor Cyan
Write-Host " Deploying Stripe Edge Functions" -ForegroundColor Cyan  
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Login with token
Write-Host "[1/3] Authenticating with Supabase..." -ForegroundColor Yellow
& $supabase login --token $Token
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Login failed. Please check your token." -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Authenticated!" -ForegroundColor Green

# Step 2: Link project
Write-Host ""
Write-Host "[2/3] Linking to project $projectRef..." -ForegroundColor Yellow
& $supabase link --project-ref $projectRef --workdir $projectRoot
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Project link failed." -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Project linked!" -ForegroundColor Green

# Step 3: Deploy the Edge Functions
Write-Host ""
Write-Host "[3/3] Deploying create-stripe-connect-account..." -ForegroundColor Yellow
& $supabase functions deploy create-stripe-connect-account --workdir $projectRoot --no-verify-jwt

Write-Host "[3/3] Deploying stripe-withdraw-funds..." -ForegroundColor Yellow
& $supabase functions deploy stripe-withdraw-funds --workdir $projectRoot --no-verify-jwt

Write-Host ""
Write-Host "====================================" -ForegroundColor Green
Write-Host " Stripe Deployment Complete!" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next Step: App mein 'Link Bank Account' button dabayen." -ForegroundColor Cyan
