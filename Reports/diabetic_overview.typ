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

#let impt(body) = block(
  fill: rgb("#fc9494"),
  stroke: (paint: rgb("#ff1900"), thickness: 1.2pt),
  radius: 6pt,
  inset: 12pt,
  width: 100%,
  [
    #text(weight: "bold")[Important :] #body
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

= SVM training for classification
10 times cross-validation on auto-optimized kernel from `fitcsvm` function. First on the HxC feature plan and then in 3D adding the Lyapunov exponent.

#rslt[
  Cloud of points in HxC feature already well splitted, not able to find enough criterias to select the best hyperplan.
]

= Kmean algorithm
To find a more simple method of classification, we applied the Kmeans algorithm on the HxC feature plane. We used the regular euclidean distance and the `Replicates,5` argument to try different initial cluster positions: 

#figure(
  image("figures/HxC K-Means Performance.png", width: 120%),
  caption: [Kmeans algorithm applied on the HxC feature plane]
)

#rslt[
  At least for the DBT2/NDBT2 datasets, the Kmeans algorithm is able to find a good separation between the two classes of patients.
]

#highlight(fill : yellow)[need to add the current distance]

= To try next
== Multi-dimensional
- 2-D Permutation Entropy (see EntropyHUB) //see in the documentation how it's defined

== Mono-dimensional
On the glucose concentration ?
- Fourier Spectrum
- AUC (power density)

#pagebreak()

= Cross-checking with new database

== Confirming (m,$tau$) parameters
To now test the robustness of our classification model, we tried to apply our metrics on a new database : 

CGMacros v1.0.0 — PhysioNet · doi:10.13026/3z8q-x658 · Gutiérrez-Osuna, Kerr, Mortazavi y Das (2025) ·
licencia CC BY-NC-SA 4.0

Producto: 45 archivos .mat repartidos en MAT\NDBT2, MAT\PDBT2 y MAT\DBT2

It is also important to notice that this time the technicians used two probes to measure the glucose concentration, called `dexcom` and `libre`. We can then double the process of verification.

#impt[
  This time, the sampling frequency is one point every minute so we need to do a quick downsample in order to compare every data on a 15-minute point basis
]

Let's see first how the points behave on the HxC feature plane. For now he still use *(m = 5, $tau$ = 2)* :

#figure(
  image("figures/Complexity-Entropy Plane: Comparison dexcom.png", width: 120%),
  caption: [HxC feature plan of the centroids of the CGMacros dataset with dexcom probe]
)

#figure(
  image("figures/Complexity-Entropy Plane: Comparison libre.png", width: 120%),
  caption: [HxC feature plan of the centroids of the CGMacros dataset with libre probe]
)

As we still observe a good separation bet ween the two classes, we got a bigger variability within each group which may disturb the classification:

#figure(
  table(
    columns: (1fr, 1fr, 1fr),
    table.header([*Group of\ patient+probe*], [*Shannon entropy (mean $plus.minus$ std)*], [*Complexity (mean $plus.minus$ std)*]),
    [Diabetic + Dexcom], [0.8161 $plus.minus$ 0.0533 ],[0.2103 $plus.minus$ 0.0357],
    [Non-diabetic + Dexcom], [0.9129 $plus.minus$ 0.0495], [0.1144 $plus.minus$ 0.0485],
    [Diabetic + Libre], [0.8164 $plus.minus$ 0.0421],[0.2244 $plus.minus$ 0.0302],
    [Non-diabetic + Libre], [0.9155 $plus.minus$ 0.0591], [0.1147 $plus.minus$ 0.0491]
  ),
  caption: [Mean and standard deviation of the Shannon entropy and complexity for each group of patient depending of the probde]
)
#pagebreak()
With the regular Kmeans algorithm we obtain:

#figure(
  image("figures/HxC K-Means Classification dexcom.png", width: 95%),
  caption: [Kmeans algorithm applied on the HxC feature plane of the CGMacros dataset with dexcom probe]
)

#figure(
  image("figures/Distance to Cluster Centroids dexcom.png", width: 100%),
  caption: [Distance to cluster centroids of the Kmeans algorithm applied on the HxC feature plane of the CGMacros dataset with dexcom probe]
)

Results are much better with the libre probe:

#figure(
  image("figures/HxC K-Means Classification libre.png", width: 95%),
  caption: [Kmeans algorithm applied on the HxC feature plane of the CGMacros dataset with libre probe]
)

#figure(
  image("figures/Distance to Cluster Centroids libre.png", width: 100%),
  caption: [Distance to cluster centroids of the Kmeans algorithm applied on the HxC feature plane of the CGMacros dataset with libre probe]
)

#figure(
  table(
  columns: (1fr, 1fr, 1fr,1fr,1fr),
  table.header([*Probe*],[*Balanced Accuracy*], [*F1-score*], [*Sensibility*], [*Specificity*]),
  [*Dexcom*], [0.79],[0.81],[0.87],[0.71],
  [*Libre*], [0.90], [0.90], [0.87], [0.93],
  [*Average quality*], [*0.845*], [*0.855*], [*0.87*], [*0.82*]
  ),
  caption: [Classification performance of the Kmeans algorithm applied on the HxC feature plane of the CGMacros dataset with dexcom and libre probes]
)

#rslt[
  Despite a greater spread in the cloud points, the Kmeans algorithm using Shannon entropy with *(m=5, $tau$=2)* parameters is still able to find a good separation between the two classes of patients. The classification performance is even better with the libre probe than with the dexcom probe.
]

== Checking clusters reusability
The next goal here is to see if the centroids of the clusters found with the Kmeans algorithm on the DBT2/NDBT2 datasets are still relevant to classify the CGMacros dataset. 

#figure(
  table(
    columns: (1fr, 1fr, 1fr),
    table.header([*Group*],[*H*], [*C*]),
    [*Diabetic*], [0.9518],[0.0791],
    [*Non-Diabetic*], [0.8303], [0.2189]
  ),
  caption : [Centroids coordinates for each group from the DBT2/NDBT2 database]
)


We then computed the distance between each point of the CGMacros datasets and the two centroids found with the Kmeans algorithm on the DBT2/NDBT2 datasets:

#figure(
  image("figures/Centroid Validation in HxC Plane dexcom.png", width: 100%),
  caption: [Distance to cluster centroids of the CGMacros dataset with dexcom probe]
)

#figure(
  image("figures/Centroid Validation in HxC Plane libre.png", width: 100%),
  caption: [Distance to cluster centroids of the CGMacros dataset with libre probe]
)

#figure(
  table(
  columns: (1fr, 1fr, 1fr,1fr,1fr),
  table.header([*Probe*],[*Balanced Accuracy*], [*F1-score*], [*Sensibility*], [*Specificity*]),
  [*Dexcom*], [0.83],[0.81],[0.73],[0.93],
  [*Libre*], [0.93], [0.93], [0.87], [1],
  [*Average quality*], [*0.88*], [*0.87*], [*0.775*], [*0.965*]
  ),
  caption: [Classification performance of the Kmeans clusters of the DBT2/NDBT2 dataset applied to the CGMacros dataset with dexcom and libre probes]
)

#rslt[
  Using the first set of centroids, we can still classify the CGMacros dataset with quality metrics similar than running the Kmeans algorithm directly on the CGMacros dataset.
]
#pagebreak()
= Complementary approach: combining all the databases

== First checks
In order to have a more robust classification model, we combined all databases and see how good could we classified them:

#figure(
  image("figures/Complexity-Entropy Plane: Comparison all.png", width: 120%),
  caption: [HxC feature plan of the centroids of the combined datasets]
)

Despite of the greater number of points, the variability within each class is still low enough to have a good separation between the two classes of patients. We can then try to classify using the same basic Kmeans algorithm as before `kmeans(X,k,'Replicates',5);
`:

#figure(
  image("figures/HxC K-Means Classification all.png", width: 100%),
  caption: [Kmeans algorithm applied on the HxC feature plane of the combined datasets]
)

We can also add the Fractal Dimension to see if we can improve any metrics:

#figure(
  image("figures/HxCxFD K-Means Classification all.png", width: 120%),
  caption: [Kmeans algorithm applied on the HxCxFD feature plane of the combined datasets]
)

#figure(
  table(
  columns: (1fr, 1fr, 1fr,1fr,1fr),
  table.header([*Feature plan*],[*Balanced Accuracy*], [*F1-score*], [*Sensibility*], [*Specificity*]),
  [*HxC*], [0.93],[0.93],[0.92],[0.94],
  [*HxCxFD*], [0.82], [0.79], [0.86], [0.98],
  ),
  caption: [Classification performance of the Kmeans algorithm applied on the HxC and HxCxFD feature planes of the combined datasets]
)


#rslt[
  For over 90% for each metrics, the Kmeans algorithm on the HxC feature plane with (m=5, $tau$=2) seems to be a good candidate for a simple and robust classification model.
]

== Optimizing the Kmeans algorithm

Matlab allows us to use different parameters to enhance the performance of the Kmeans algorithm :
- Distance metric: `sqeuclidean, cityblock, cosine, correlation`
- `MaxIter` : maximum number of iterations, here 100, 1000 and 5000.
- `Replicates` : number of times to repeat the clustering using new initial cluster centroid, here up to 5
- Starting cluster centroid: `plus, cluster, sample`

It leads to the test of 4*3*5*4 = 240 different combinations of parameters. We then computed the classification metrics for each combination and plotted the results:

#figure(
  table(
    inset: 8pt,
    columns: (1.4fr, 1fr, 0.8fr, 0.9fr, 0.9fr, 1.1fr, 1fr, 1fr, 1fr),
    align: (col, row) => if col == 0 { left + horizon } else { center + horizon },
    fill: (col, row) => if row == 0 { rgb("f1f5f9") },
    stroke: (x, y) => if y == 0 { (bottom: 1.5pt + rgb("cbd5e1")) } else { 0.5pt + rgb("e2e8f0") },

    table.header(
      [*Metric*], [*Distance*], [*MaxIter*], [*Replicates*], [*Start*],
      [*Balanced\ Accuracy*], [*F1-score*], [*Sensibility*], [*Specificity*]
    ),

    [Best\ Balanced Accuracy], [`cosine`], [100], [1], [`plus`],
    table.cell(fill: rgb("fef08a"))[*0.93*], [0.92], [0.92], [0.93],

    [Best\ F1-score], [`sqeuclidean`], [1000], [1], [`plus`],
    [0.93], table.cell(fill: rgb("fef08a"))[*0.93*], [0.92], [0.94],

    [Best\ Sensibility], [`cosine`], [5000], [1], [`plus`],
    [0.93], [0.93], table.cell(fill: rgb("fef08a"))[*0.92*], [0.94],

    [Best\ Specificity], [`correlation`], [100], [1], [`plus`],
    [0.51], [0.04], [0.02], table.cell(fill: rgb("fef08a"))[*1*]
  ),
  caption: [Top configurations by metric]
)
More exactly, it appears that numerous configurations lead to the same best metrics, so we indicated in this table an example of best configuration for each metric trying also to optimize the others.
We can also notice that we reached one more time what seems to be the best performances taht we got before: 
#align(center)[*Balanced Accuracy = 0.93, F1-score = 0.93, Sensibility = 0.92\ and Specificity = 0.94*]

To ensure this result, we looked for for a configuration matchin all 4 best metrics. Unfortunately, this configuration does not exist, at least for the tested parameters. 

We then selected the configuration that hit 3 out of 4 best metrics. This time, we found up to 102 configurations that are matching, all of them with the quality metrics mentionned just earlier! 

We can then draw this first draft of parameters selection politic:
- Distance metric: `cosine and sqeucliean` are the best candidates
- Maximum of Iteration: we managed to reach the best metrics with 100, 1000 and 5000 iterations.
- Replicates: the occurances of 1,2,3,4 or 5 are almost the same.
- Starting cluster centroid: the four forms occur almost the same.

#rslt[
  This first optimization of the Kmeans algorithm shows that we can reach a good classification performance with a simple configuration, the parameter that seems to have the most impact is the distance metric, with `cosine` and `sqeuclidean` being the best candidates.

  The complete table of best configurations can be generated using the `HxC_sweep_kmean.m` script.
]

= Final step : classifying a third database
We have got efficient (m,$tau$) parameters to compute permutation entropy as well as good parameters to wisely run Kmeans algorithm. The last step is to check if we can classify a third database with the same parameters and the centroids found with the Kmeans algorithm on the combined datasets.

First step is to fix the parameters. We will use obviously the (m=5, $tau$=2) parameters to compute the permutation entropy and the following Kmeans parameters:
- Distance metric: `cosine`
- Maximum of Iteration: 100
- Replicates: 1
- Starting cluster centroid: `plus`
as it is one of the configuration that hit 3 out of 4 best metrics and does not need much computation time

We obtain:
#figure(
  table(
    columns: (1fr, 1fr, 1fr),
    table.header([*Group*],[*H*], [*C*]),
    [*Diabetic*], [0.8171],[0.2201],
    [*Non-Diabetic*], [0.9386], [0.0930]
  ),
  caption : [Centroids coordinates for each group from the coupled database]
)

== Madrid dataset
We managed to obtain Madrid dataset with 208 patients, 17 of them being diabetic. That's the first potantial problem: an unbalanced dataset. Moreover, the measurements were taken every 5 minutes for 2 days, leading to only 250 points after downsampling.
The two others datasets contains around 1000-2000 points per patients, so the $tau$ parameter might not be relevant anymore. Moreover, the assumption tha99t m! << N the sample size is not true anymore.

== Hall dataset