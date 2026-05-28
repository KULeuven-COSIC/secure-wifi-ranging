# Secure Wi-Fi Ranging Today: Security and Adoption of IEEE 802.11az/bk

The repository contains source code and resources supporting the paper `Secure Wi-Fi Ranging Today: Security and Adoption of IEEE 802.11az/bk`, which will appear at [ARES](https://www.ares-conference.eu/) 2026.

> **Abstract**. Ranging and localisation have become critical for many applications and services. The Wi-Fi (IEEE 802.11) standard is a natural candidate for providing these functions across diverse environments, given its widespread deployment. The IEEE 802.11az amendment, finalised in 2023, introduces “Next Generation Positioning” mechanisms to secure and harden the existing insecure Wi-Fi Fine Timing Measurement (FTM) ranging solution. Moreover, the recent IEEE 802.11bk amendment increases the available bandwidth with the goal of approaching the centimetre-level ranging accuracy of ultra-wideband (UWB) systems. This paper examines to what extent these promises hold from a security and deployability perspective.
We analyse the core mechanisms of secure Wi-Fi ranging as defined in IEEE 802.11az and IEEE 802.11bk at both the logical and physical layers, combining standards analysis with simulations and measurements on commercial and development hardware. At the logical layer, we show how common deployment choices can result in unauthenticated ranging, downgrade attacks, and simple denial-of-service attacks, making it difficult to securely realise many high-stakes use cases. At the physical layer, we study the predictability of secure ranging waveforms, the security impact of symbol repetition, and how waveform design choices affect compliance with spectral masks under realistic RF behaviour.
Our results show that secure Wi-Fi ranging is highly sensitive to configuration choices and is non-trivial to implement on existing hardware. This is also evidenced by the currently limited support for secure Wi-Fi ranging in commodity devices. This paper provides practical guidelines for using secure FTM safely and recommendations to vendors and standardisation bodies to improve its robustness and deployability.

## Code availability and third-party material

Our experimental workflow is based in part on the MathWorks [802.11az waveform generation example](https://www.mathworks.com/help/wlan/ug/802-11az-waveform-generation.html). As MathWorks code is copyrighted, we cannot redistribute it in this repository. Therefore, we provide only our original functions and code sections, which are intended to be incorporated into the corresponding MathWorks framework by users with legitimate access to it.

## Integration of the provided code

Our repository-specific functions are provided in the `custom-functions` folder. These functions are intended to be incorporated into the corresponding MathWorks workflow. Additional documentation in that folder explains the role of each function, how it relates to the original example, and how it was used in our evaluation.

## Board-specific code and configuration files

This repository does not include any board-specific code, firmware, or configuration files related to the boards used for our measurements and for obtaining the waveforms. Access to the relevant platform materials required acceptance of a non-disclosure agreement, and we are therefore unable to share any board-related software or configuration artefacts used in our evaluation.

## Acknowledgments

This work was supported by the Flemish Government through the Cybersecurity Research Program (VOEWICS02), by COST Action CA22168 – Physical Layer Security for Trustworthy and Resilient 6G Systems, by the “University SAL Labs” initiative of Silicon Austria Labs and its Austrian partner universities for applied fundamental research for electronic-based systems, and by the Linz Center of Mechatronics in the framework of the Austrian COMET-K2 programme.

