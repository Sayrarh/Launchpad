# Building a decentralised IDO launchpad contract

---

## Introduction

Welcome to this tutorial where we will delve into the exciting world of Initial DEX Offerings (IDOs) and explore the possibilities of launching projects on a decentralized platform. In this tutorial, we will specifically focus on building a decentralized launchpad on the Celo blockchain.
Whether you are a developer with some experience in Solidity or someone looking to expand their skills, this tutorial will equip you with the knowledge and tools to create a decentralized launchpad application on Celo.

## Table of Contents

[Building a decentralised launchpad contract on Celo Blockchain](#Building-a-decentralised-launchpad-contract-on-Celo-Blockchain)

- [Introduction](#introduction)
- [Table of Contents](#table-of-contents)
- [Objective](#objective)
- [Prerequisites](#prerequisites)
- [Requirements](#requirements)
- [Initial DEX Offering(IDO)](#initial-dex-offeringido)
  - [The concept of IDO](#the-concept-of-ido)
  - [How IDO works](#how-ido-works)
  - [Major Difference Between ICO and IDO](#major-difference-between-ico-and-ido)
- [Launchpad](#launchpad)
  - [Steps involved in building an IDO Launchpad](#steps-involved-in-building-an-ido-launchpad)
- [Tutorial](#tutorial)
  - [STEP 1 - Set up Hardhat Environment](#step-1---setup-hardhat-environment)
  - [STEP 2 - Create your Smart contracts](#step-2---create-your-smart-contracts)
    - [Launchpad Contract Explained](#launchpad-contract-explained)
  - [STEP 3 - Testing your contracts](#step-3---testing-your-contracts)
  - [STEP 4 - Deploying your contracts](#step-4---deploying-your-contracts)
  - [Conclusion](#conclusion)

## Objective

The objective of this tutorial is to provide developers with a comprehensive understanding of IDOs and the benefits of launching on decentralized platforms. By the end of this tutorial, you will have a solid grasp of the technical aspects involved in building a launchpad smart contract on the Celo blockchain. This tutorial will guide you through the process of creating the smart contract, integrating it with the Celo network, and testing its functionality.
Let's dive in and unlock the world of decentralized finance and project launchpads on the Celo blockchain!

## Prerequisites

Before diving into building a decentralized launchpad on the Celo blockchain for Initial DEX Offerings (IDOs), it is important to ensure you have a strong foundation in the following areas:

- Solidity: Solidity is the primary programming language used for writing smart contracts on the Celo blockchain. Make sure you have a good understanding of Solidity and its syntax.

- Command Line Proficiency: Familiarize yourself with using the command line interface (CLI), such as Terminal or Command Prompt, as you will need to run commands and scripts throughout the tutorial.

- Proficiency in Hardhat: Hardhat is one of development environments specifically designed for building, testing, and deploying smart contracts on the Celo blockchain.

## Requirements

To successfully follow along with this tutorial, make sure you have the following requirements fulfilled:

- Text Editor: We recommend using Visual Studio Code (VS Code) as your text editor for this tutorial. VS Code is a widely-used integrated development environment (IDE) that offers powerful features for writing and editing code.

- Node.js: Install Node.js on your system, preferably version 10 or higher. Node.js provides a runtime environment for executing JavaScript code outside of a web browser.

- npm (Node Package Manager): npm is a package manager for JavaScript and comes bundled with Node.js. You will need npm to install and manage dependencies required for the development process.

## Initial DEX Offering(IDO)

An Initial DEX Offering (IDO) is a fundraising method for new cryptocurrency projects where tokens are sold directly on a decentralized exchange (DEX). It is an alternative to traditional Initial Coin Offerings (ICOs) and Initial Exchange Offerings (IEOs), which are often centralized and conducted on centralized exchanges.

### The concept of IDO

Imagine you have an amazing idea for a new cryptocurrency project, such as a decentralized gaming platform. However, you need funds to turn your idea into reality. In the traditional world, raising money for your project can be quite challenging. Investors might have specific demands or requirements, and the process itself can be time-consuming.

But now, there's a new way to raise funds called an Initial DEX Offering or IDO. It's like a virtual marketplace where people from all over the world can purchase tokens that represent their ownership in your project. The unique thing about IDOs is that they take place on decentralized platforms, meaning there's no central authority in control. It's similar to a digital marketplace where people can directly buy tokens using their preferred cryptocurrencies like Celo or Ethereum.

By launching your project through an IDO, you can reach a global audience of potential investors and supporters. The decentralized nature of IDOs offers more freedom and flexibility compared to traditional fundraising methods. You won't have to rely solely on the decisions and demands of specific investors or companies. Instead, you can connect directly with a wide range of individuals who believe in your project and want to be part of its success.

### Major Difference Between ICO and IDO

The major difference between an ICO and an IDO is where the tokens are sold. ICO are sold on centralized exchanges, while IDO are sold on decentralized exchanges. This has a number of implications, including:

- Liquidity: IDO tokens are typically more liquid than ICO tokens, as they can be traded on multiple decentralized exchanges. This makes it easier for investors to buy and sell IDO tokens, which can lead to higher prices.
- Security: Decentralized exchanges are less susceptible to hacks and fraud than centralized exchanges. This makes IDO contracts a more secure option for investors.
- Cost: IDO typically have lower fees than ICO. This is because there is no need to pay a centralized exchange to list the tokens.

### How IDO works

Let's walk through the typical steps involved in an IDO:

- Project Preparation: The project team develops their cryptocurrency project, such as a new token, decentralized application, or platform. They define the project's goals, roadmap, and tokenomics.

- Smart Contract Creation: The project team creates a smart contract, this smart contract defines the rules and parameters of the IDO, such as the token sale price, token distribution, and fundraising cap.

- Platform Selection: The project team selects a decentralized exchange (DEX) platform to host their IDO, which is what we will be building in this tutorial.

- Token Allocation: The project team determines the allocation of tokens for the IDO. They typically reserve a portion of the tokens for the IDO participants, team members, advisors, and community incentives.

- Investment Period: The IDO opens for a specific period during which participants can invest. Participants send their desired cryptocurrency (such CELO) to the smart contract address associated with the IDO. In return, they receive the project's tokens based on the predefined token price.

- Token Distribution: After the investment period ends, the project's tokens are automatically sent to the participants' wallets through the smart contract. The timing of the distribution, whether immediate or at a designated future time, depends on the specific logic programmed into the smart contract. This is why it is essential for developers to thoroughly review the smart contract code before making any investment in a project. By carefully examining the smart contract, developers can understand how the token distribution process is designed, including any potential delays, conditions, or restrictions that may apply. This diligence ensures that developers have a clear understanding of how their investments will be handled and empowers them to make well-informed decisions.

- Liquidity Provision: After the IDO, the project team and liquidity providers may add liquidity to the token pair on the DEX platform. This ensures that the project's tokens have sufficient trading volume and liquidity for further trading.

_Note: Each IDO may have its own specific variations and processes depending on the platform and project's requirements. However, the general idea is to provide a decentralized and transparent fundraising method where individuals can directly participate in supporting and investing in new cryptocurrency projects._

## Launchpad

A launchpad is a platform that facilitates the launching of new cryptocurrency projects, typically through Initial DEX Offerings (IDOs) or Initial Coin Offerings (ICOs). It acts as a launching pad for these projects, providing the infrastructure and tools necessary for their successful introduction to the market.
<br/>
A launchpad serves as an intermediary between project teams and it's potential investors. It also provides a space for investors to discover and participate in these projects.
<br/>

#### NOTE !!!

In an Initial DEX Offering (IDO), the tokens are made available directly on a decentralized exchange (DEX) rather than through a traditional centralized exchange. In this type of fundraising model, whitelisting is not necessary because anyone with access to the DEX platform can participate and invest in the IDO.
<br/>

Whitelisting is often used in other fundraising models, such as Initial Coin Offerings (ICOs) or token sales conducted on centralized exchanges. In these cases, the project team may require interested investors to register their wallet addresses in advance and be approved for participation. Whitelisting helps ensure that only approved individuals or entities can invest in the token sale.
<br/>

However, in an IDO, since the tokens are directly listed on a DEX, anyone with a compatible wallet and access to the DEX can participate without the need for prior approval or whitelisting. This allows for a more open and decentralized investment process, where investors can interact with the IDO contract on the blockchain and acquire tokens in a trustless manner.
<br/>

Please note that the mechanics and requirements of IDOs can differ based on the platform or protocol utilized. For instance, in this tutorial, the launchpad being discussed requires investors' addresses to be whitelisted prior to the IDO.

Article is published [here, continue reading ...](https://celo.academy/t/building-a-decentralised-ido-launchpad-on-celo-blockchain-a-comprehensive-tutorial-for-solidity-developers/864)

### Deployed Contract Address

- Yamtoken Contract Address is 0xFdaF7C2F1e8116120A037B858044Cb73c3c6dE9d
- IDO LaunchPad Contract Address is 0x567946e9f6ECBde534580bC516b194906dC1efEc
