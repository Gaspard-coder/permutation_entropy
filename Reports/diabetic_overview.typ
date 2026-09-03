#set page(
  paper: "a4",
  margin : 2.5cm
)

#set text(
  font: "New Computer Modern",
  size: 12pt,
  lang: "en",
)

#set par(
  justify: true,
  leading: 0.65em,
  first-line-indent: 0pt,
)

#set page(numbering: "1")

#set heading(numbering: "1.")

#let nb(body) = block(
  fill: rgb("#eaf3ff"),
  stroke: (paint: rgb("#4a90e2"), thickness: 1.2pt),
  radius: 6pt,
  inset: 12pt,
  width: 100%,
  [
    #text(weight: "bold")[NB :] #body
  ],
)

#let rslt(body) = block(
  fill: rgb("#fff8af"),
  stroke: (paint: rgb("#ffdc00"), thickness: 1.2pt),
  radius: 6pt,
  inset: 12pt,
  width: 100%,
  [
    #text(weight: "bold")[Result :] #body
  ],
)
#align(right)[
  #datetime.today().display("Last version : [day]/[month]/[year]")
]
#align(center)[
  #text(size: 19pt, weight: "bold")[
    A brief overview of diabetes detection using permutation entropy
  ]
]


= Introduction

== Materials 
For this project, we are using the following materials:
- DBT2 and NDBT2, 2 datasets of 20 diabetics and non diabetics patients each. The .mat files are composed of the glucose concentration *G* vs time (T#sub[sample] = 15min ie F#sub[sample] = 1/900 Hz) and the "food activity" *S* vs time, linked to the alimentation of each patient.
// How is defined the food activity ?
- The permutation entropy and all its derivate concepts. We will use MATLAB and the EntropyHUB library as well as homemade code made by Dr. Walter Legnani and its students.

== Goals and plan
The main goal of this project is to develop a classifier that is able to distinguish between diabetics and non diabetics patients. To achieve this, we will try several machine learnings techniques based on well-chosen metrics and parameters.

Rather than analysing the glucose concentration alone, we also try to correlate it with the "food activity" as mentionned earlier, in order to develop a more robust classifier that is able to take into account the alimentation of the patients.

We can build the plan of the project as follows:
1. A preliminary study to find the most relevant embedding dimension (*m*) and embedding time delay (*$tau$*) in order to apply permutation entropy tools
2. The selection of the most relevant metrics and parameters to feed the classifier
3. The choice and development of the classifier
4. The evaluation of the classifier's performance and its optimization

= Preliminary study: finding the most relevant (m,$tau$) combination

== CxH Feature plan

To find the most relevant embedding dimension (*m*) and embedding time delay (*$tau$*), we first focused on the evolution of glucose's concentration over time. We used the standard Complexity-Entropy feature plan in order to find the combination that splits the most the two classes of patients. To be more precise, we used the MPR Complexity denoted C and the normalized permutation entropy denoted H.
// Need more definition ?

== Finding the parameters

To compare the two classes, we computed the euclidean centroid of each class and then the euclidean distance between the two centroids. The combination of (m,$tau$) that maximizes this distance is the one we will use to compute the metrics for the classifier.

We know that we consider more or less chaotic behaviors so to give an order of magnitude, we expect the centroids to have a entropy H < 0.9 and a complexity C > 0.1.

In order to find bounds to the value of the parameters, the litterature suggests that  usually $m in [3,7]$ and rarely exceeds 5 or 6 for physiological signals. 

We also chose to limit the maximum value of $tau$ to 3, because we know that the glucose concentration is sampled every 15 minutes, so a $tau$ of 3 would correspond to a time delay of 45 minutes, which is already quite long for a physiological signal.

Using the MATLAB functions `HXC_centroid.m` and `HXC_param_sweep_euclide.m`, we computed the distance between the two centroids for all the combinations :

#v(1.5cm)
#figure(
  image("figures/Complexity_Entropy_Plane_Centroids_Diabetic.png", width: 120%),
  caption: [HxC feature plan of the centroids of the diabetic dataset]
)

#figure(
  image("figures/Complexity_Entropy_Plane_Centroids_non_diabetic.png", width: 120%),
  caption: [HxC feature plan of the centroids of the non-diabetic dataset]
)

At first glance, we have several candidats that behave a physilogical chaotic signal. We obtain after computation : 

#figure(
  image("figures/Distance_vs_m_(Standalone).png", width: 100%),
  caption: [Distance between centroids vs. embedding dimension and time delay]
)

We can furthermore compute the standard deviation around the centroids to be sure they do not overlap:

#figure(
  image("figures/Complexity_Entropy_Plane_Comparison_5_2_(firt result).png", width: 120%),
  caption: [HxC feature plan with standard deviation of the (5,2) combination]
)
#rslt[
 From this approach, we concluded that *(m = 5, $tau$ = 2)* is the most relevant combination to compute permutation entropy.
]
#nb[
  This way of selection is mainly empirical and does not necesseraly provide the optimized combination. To be more precise on the choice of $tau$, we can also compute the autocorrelation of the datas.
]

= Selections of the most relevant metrics

Now that we have found a satisfying set of parameters, we have to find metrics that link *G* and *S* and show different behaviors between diabetic and non-diabetic patients.

== Mutual information
// Maybe need a little definition
To have an idea of the quantity of information shared between *G* and *S*, we computed with `internal_PMI_sweep.m` the mutual information of each patient and the mean mutual information of each class :

#figure(
  image("figures/internal PMI Sweep Results DBT2 5-1.png", width: 100%),
  caption: [Mean, standard deviation and individual mutual information of G and S for each diabetic patient]
)

#figure(
  image("figures/internal PMI Sweep Results NDBT2 5-1.png", width: 100%),
  caption: [Mean, standard deviation and individual mutual information of G and S for each non-diabetic patient]
)

#pagebreak()
#figure(
  table(
  columns: (1fr, 1fr, 1fr),
  table.header([*Group of patient*], [*Mean Mutual Information of G and S*], [*Standard deviation*]),
  [Diabetic], [2.2145],[0.2594],
  [Non-diabetic], [2.8857], [0.0545]
  ),
  caption: [Mean mutual information of G and S for each class of patients]
)

#rslt[
  The mean mutual information of the non-diabetic patients is higher than the one of the diabetic patients, which means that the glucose concentration is more correlated to the food activity for healthy patients.

  We observe as well that diabetic patients have more spreaded mutual information values, meaning one more time as smaller correlation between the glucose concentration and the food activity for them.
]

== Transfer entropy
// Little definition also
To go further on the characterisation of the correlation between *G* and *S*, we computed the transfer permutation entropy in order to measure the directed transfer of information between the two signals *G* and *S*, using the `internal_TE_sweep.m` function :

#figure(
  image("figures/internal TE Sweep Results DB2 5-2.png", width: 120%),
  caption: [Mean, standard deviation and individual transfer entropy of G and S for each diabetic patient]
)

#figure(
  image("figures/internal TE Sweep Results NDBT2 5-2.png", width: 120%),
  caption: [Mean, standard deviation and individual transfer entropy of G and S for each non-diabetic patient]
)

#figure(
  table(
  columns: (1fr, 1fr, 1fr),
  table.header([*Group of patient*], [*Mean Transfer Permuation Entropy S $arrow$ G*], [*Standard deviation*]),
  [Diabetic], [0.7611],[0.0890],
  [Non-diabetic], [2.1515], [0.0659]
  ),
  caption: [Mean mutual information of G and S for each class of patients]
)

#rslt[
  The transfer permutation entropy of non-diabetic patient is around 3 times higher than the one of diabetic patients, highlighting a stronger dependency of *G* on *S* for healthy patients. This is consistent with the mutual information results.

  Once again, the diabetic patients values are more spreaded, underlining a thiner correlation between glucose concentration and food activity for them.
]

#highlight(fill : aqua)[To be continued...]





= To try next
== Multi-dimensional
- 2-D Permutation Entropy (see EntropyHUB) //see in the documentation how it's defined

== Mono-dimensional
On the glucose concentration ?
- Fourier Spectrum
- AUC (power density)
- Fractal dimension (with Higuchi's method)
- Lyapunov exponent