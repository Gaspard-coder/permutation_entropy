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

#pagebreak()
== Weighted permutation entropy
By plotting the signals of the glucose concentration for healty and diabetic patients, we observed that the signal amplitude is bigger 
for the diabetic group. We then tried to compute the WHXC feature plan which stand for Weighted HxC feature plan, using the weighted permutation entropy as defined in *"Weighted-permutation entropy: A complexity measure for
time series incorporating amplitude information"* by B. Fadlallah, B. Chen, A. Keil and J. Príncipe.

As we used a new definition of the permutation entropy, we had to find new (m,$tau$) parameters that maximize the distance between the two classes:

#figure(
  image("figures/WPE_best_distance_diabet.png", width: 100%),
  caption: [Weighted HxC feature plan of the centroids of the diabetic dataset]
)

As shown, the two best sets of parameters seem to be (m = 5, $tau$ = 2) and (m = 4, $tau$ = 2):

#figure(
  image("figures/Complexity-Weigthed Entropy Plane: Comparison 5-2.png", width: 120%),
  caption: [Comparison of the weighted permutation entropy for the m = 5 and $tau$ = 2]
)

#figure(
  image("figures/Complexity-Weigthed Entropy Plane: Comparison 4-2.png", width: 120%),
  caption: [Comparison of the weighted permutation entropy for the m = 4 and $tau$ = 2]
)

Nb : discontinuity in the theoritical max complexity are due to MATLAB overlapping plots.

Here we observe an interesting behavior: (5,2) configuration gives the maximum distance between the two classes of patients but the (4,2) configuration shows a more satisfying space distribution.
By more satisfying, we mean that the two clouds of points respectively lie in areas consistent with their signal type (a changing mix between random and chaotic).

#rslt[
  For the rest of the study, we will use (m = 4, $tau$ = 2) set of parameters to compute the weighted permutation entropy and its associated complexity, as it better reflects the nature of the signals.
]

#nb[
  This criteria of computing the euclidean distance between the centroids to find the best set of parameters seems a bit too naive if used alone. We might include the standard deviation but maybe also some thresholds to ensure each centroid's group stays in an
  area consistent with their physical behavior.
]

#highlight(fill : aqua)[What to do next? Try to compute the mutual information and transfer entropy using this type WPE?]


== Lyapunov exponent
In order to find others metrics to feed the feature space of the classifier, we also computed the average lyapnuov exponent of each class, using the glucose concentration:

#figure(
  table(
    columns: (1fr, 1fr, 1fr),
    table.header([*Group of patient*], [*Mean Lyapunov exponent*], [*Standard deviation*]),
    [Diabetic], [0.000278],[0.000162],
    [Non-diabetic], [ 0.000203], [0.000123]
  ),
  caption: [Mean Lyapunov exponent for each group of patient with the samping frequency f#sub[s] = 1/900 Hz]
)

#rslt[
  At first sight, it seems that the lyapunov exponent is in this case not a relevant metric to distinguish the two classes. However, the standard deviation is too high for now to really conclude anything.

]

=== Emphasizing variations
We already observed that the biggest difference between sick and healthy subjects lie in the variability and peaks in the glucose blood density.

Given that, we tried to substract the mean value of each signal before calcultation in order to compute Lyapunov exponent mainly on the variations :

#figure(
  table(
    columns: (1fr, 1fr, 1fr),
    table.header([*Group of patient*], [*Mean Lyapunov exponent on sub-mean signals*], [*Standard deviation*]),
    [Diabetic], [0.000405],[0.000031],
    [Non-diabetic], [ 0.000285], [0.000021]
  ),
  caption: [Mean Lyapunov exponent on sub-mean signals for each group of patient with the samping frequency f#sub[s] = 1/900 Hz]
)

#rslt[
  With a standard deviation of around 7% of the value, we can now distinguish the group without overlapping values!
]

== Higuchi's fractal dimension
We also computed the fractal dimension of the glucose concentration using Higuchi's method. The question then is which depth k#sub[max] to use. Here for k#sub[max] = 2, corresponding to a evolution of 30min:

#figure(
  table(
    columns: (1fr, 1fr, 1fr),
    table.header([*Group of patient*], [*Mean Fractal Dimension*], [*Standard deviation*]),
    [Diabetic], [1.1540],[0.0453],
    [Non-diabetic], [ 1.2737], [0.0124]
  ),
  caption: [Mean Fractal Dimension for each group of patient\ with the max depth k#sub[max] = 2]
)

The time of observation seemed a bit too short to distinguish different behaviors. We tried bigger time windows:

#figure(
  image("figures/Fractal Dimension Sweep.png", width: 110%),
  caption: [Mean Fractal Dimension for each group of patient with different max depth k#sub[max]]
)

#rslt[
After k#sub[max] = 6, which corresponds to a time window of 1h30, we seems to have reached a stationnary difference between diabetic and non-diabetic patients of around 0.2603.
]

#nb[
  The standard deviations are not overlapping but is this difference enough to be used in the feature set?
]

=== Emphasizing variations
We also tried to compute the fractal dimension on the sub-mean signals, in order to achieve the same goal as before:

#figure(
  table(
    columns: (1fr, 1fr, 1fr),
    table.header([*Group of patient*], [*Mean Fractal Dimension on sub-mean signals*], [*Standard deviation*]),
    [Diabetic], [1.2832],[0.06],
    [Non-diabetic], [ 1.5478], [0.02]
  ),
  caption: [Mean Fractal Dimension on sub-mean signals for each group of patient with the samping frequency f#sub[s] = 1/900 Hz]
)

#rslt[
  The standard deviations now are not overlapping, and the difference in fractal dimension between the two groups is significant.
]

= To try next
== Multi-dimensional
- 2-D Permutation Entropy (see EntropyHUB) //see in the documentation how it's defined

== Mono-dimensional
On the glucose concentration ?
- Fourier Spectrum
- AUC (power density)
