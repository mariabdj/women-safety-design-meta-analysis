# Citation check (protocol draft 1, 27 October 2026)

Every sentence of `protocol.md` that attributes a finding or an idea to a source, checked against that source. "Full text" = read in the article itself; "abstract" = only the abstract was available (paywalled).

| # | Claim in the protocol | Source | Checked against | Result |
|---|---|---|---|---|
| 1 | Women report more fear of crime than men, for every type of offence | Ferraro 1996 | abstract | Supported ("women are more afraid of all victimizations"). Earlier draft cited Hale 1996 and added that men are more often victims: not confirmed by Hale's abstract, so both removed |
| 2 | Shadow of sexual assault hypothesis | Ferraro 1996 | abstract | Supported |
| 3 | Prospect, refuge, escape and fear of crime | Fisher & Nasar 1992 | abstract | Supported ("fear of crime was highest in areas with refuge for potential offenders and low prospect and escape") |
| 3b | Prospect-refuge theory originates in Appleton 1975 | Appleton 1975 (book) | secondary: Fisher & Nasar 1992 | Standard attribution; book not consulted |
| 4 | "Eyes on the street" | Jacobs 1961 (book) | not consulted | Standard attribution of the phrase; book not consulted |
| 5 | Incivilities / broken windows raise fear | Wilson & Kelling 1982 (magazine) | not consulted | Standard attribution; original not consulted |
| 6 | Lighting and reassurance | Fotios, Unwin & Farrall 2014 | full text (Documentation/04) | Supported |
| 7 | 47 evaluations, narrative synthesis, little evidence that street lighting reduces fear | Lorenc et al. 2013 | full text (Documentation/04) | Supported |
| 8 | Narrative review of women's perceived safety | Dubey, Bailey & Lee 2025 | abstract | Supported (narrative review, 32 articles) |
| 9 | 50 studies, narrative, variation among women, excludes women-men comparisons | te Braak & van Tienoven 2025 | full text (Step 0, `overlap_search/raw/close_matches/TeBraak2025_vub.md`) | Supported |
| 10 | 47 studies; gender only as study-level moderators, n.s.; lighting most frequent intervention | Knabe et al. 2026 | OSF records and analysis file (Step 0) | Supported (caption "Lighting interventions are most prevalent") |
| 11 | NYC street lighting RCT in public housing, at least 36% fewer outdoor night-time index crimes | Chalfin et al. 2021 | full text of the NBER working paper w25798 (same study) | Supported |
| 12 | Vacant lot restoration in Philadelphia reduced gun violence and crime, mainly below the poverty line, and safety concerns | Branas et al. 2018 | full text (PNAS, open access) | Supported (−29.1% gun violence, −13.3% crime in neighbourhoods below the poverty line; −57.8% safety concerns) |
| 13 | Meta-analysis of 13 evaluations; lighting reduces crime | Welsh & Farrington 2008 | full text (Campbell, open access) | Supported |
| 13b | RES = ad/bc with a, b treated before/after and c, d control before/after; ln(RES) variance from 1/a+1/b+1/c+1/d under a Poisson assumption; overdispersion | Welsh & Farrington 2008 | full text | Supported. The draft had the cells in the wrong order (sign reversed in the text, not in the code): corrected. Their exact overdispersion equation is an image that could not be read, so the protocol uses a simple, stated sensitivity analysis (variance doubled) instead of claiming their formula |
| 14 | No green/blue space intervention specifically to prevent violence against women and girls; 8 interventions from 2,303 papers | Cleland et al. 2025 | full text (open access) | Supported, wording matches |
| 15 | SMCR = raw score standardisation | Becker 1988 | metafor reference manual (Documentation/03) | Supported. Replaces Morris 2007, which is about pretest-posttest-control designs |
| 16 | WebPlotDigitizer intercoder reliability and validity | Drevon et al. 2016 | abstract | Supported |
| 17 | Revised JBI tool for quasi-experimental studies | Barker et al. 2024 | abstract | Supported (our six items are our own adaptation, stated as such) |
| 18 | Methods references (PRISMA 2020, PRISMA-S, PRISMA-P, NIRO-SR, SWiM, ASReview, metafor, three-level models, CR2, I², prediction intervals, Egger, modified precision, SESOI, equivalence tests, power) | see References | titles and abstracts; NIRO-SR and PRISMA-P full texts (Documentation/01) | Used for what each paper is about |

**Full texts to obtain before Stage 2 (paywalled, optional for Stage 1):** Ferraro 1996 (Social Forces), Fisher & Nasar 1992 (Environment and Behavior), Drevon et al. 2016 (Behavior Modification), Barker et al. 2024 (JBI Evidence Synthesis). The claims above rely only on what their abstracts state.
