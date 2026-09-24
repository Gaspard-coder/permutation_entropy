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

#outline()

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

== Optimizing the Kmeans algorithm <kmeans_param>

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
The two others datasets contains around 1000-2000 points per patients, so the $tau$ parameter might not be relevant anymore. Moreover, the assumption that m! << N the sample size is not true anymore.

== Hall dataset
This dataset contains Continuous Glucose Monitoring (CGM) data from a study by Hall et al. (2018) analyzing glucose dysregulation patterns.

Participants ($n=57$) aged 25–76 categorized based on ADA diagnostic criteria into three groups:
- Type 2 Diabetic ($n=5$)
- Prediabetic ($n=14$)
- Normoglycemic ($n=38$)

Originally recorded every 5 minutes, with resampled 15-minute versions (~700 data points per subject) provided for time-series analysis.

We first compute the dataset in the HxC feature plane with still the (m=5, $tau$=2) parameters:

#figure(
  image("figures/Complexity-Entropy Plane: Comparison Hall.png", width: 120%),
  caption: [HxC feature plan of the centroids of the Hall dataset]
)

Despite the unbalanced dataset, we can still see a good separation between the two classes of patients. We then applied the Kmeans algorithm with the parameters mentionned earlier (Distance metric: `cosine` ;Maximum of Iteration: 100; Replicates: 1; Starting cluster centroid: `plus`):

#figure(
  image("figures/HxC K-Means Classification - Hall.png", width: 120%),
  caption: [Kmeans algorithm applied on the HxC feature plane of the Hall dataset (Accuracy = 84.7%, F1-score = 0.93, Sensibility = 0.89 and Specificity = 0.80)]
)

#figure(
  table(
    columns: (1fr, 1fr, 1fr),
    table.header([*Group*],[*H*], [*C*]),
    [*Diabetic Hall*], [0.8580],[0.1985],
    [*Diabetic coupled*], [0.8171],[0.2201],
    [*Non-Diabetic Hall*], [0.9363], [0.1071],
    [*Non-Diabetic coupled*], [0.9386], [0.0930]
  ),
  caption : [Centroids coordinates for each group from the Hall dataset]
)
The values of the centroids are constistent with the ones found with the Kmeans algorithm on the combined datasets, which is a very good sign of robustness of our classification model!

We can then usse the centroids found with the Kmeans algorithm on the combined datasets to classify the Hall dataset:

#figure(
  image("figures/Centroid Validation in HxC Plane - Hall dataset.png", width: 120%),
  caption: [Kmeans algorithm applied on the HxC feature plane of the Hall dataset using the centroids found with the Kmeans algorithm on the combined datasets (Accuracy = 86.1%, F1-score = 0.95, Sensibility = 0.92 and Specificity = 0.80)]
)

The classification performance is even better than running the Kmeans algorithm directly on the Hall dataset. However, the unbalanced dataset might have an impact on the metrics, especially the specificity.
#pagebreak()
= Overall results for the regulare shannon permutation entropy
We will now summarize the global characteristics of the different datasets and the classification performance of the Kmeans algorithm on each of them.

== Datasets used
- `DBT2/NDBT2 dataset` ($n=39$) with 19 DBT2 patients and 20 NDBT2 patients, average 1200 points per patient, 15-minute sampling frequency.
- `CGMacros` ($n=29$) with 14 DBT2 patients and 15 NDBT2 patients, average 1000 points per patient, resampled to 15-minute sampling frequency. The measurements were taken with two different probes: dexcom and libre.
- `Hall` ($n=43$) with 5 DBT2 patients and 38 NDBT2 patients, average 700 points per patient, resampled to 15-minute sampling frequency.

== Permutation entropy and kmeans parameters
Following our preliminary study, we computed the regular Shannon permutation entropy and MPR complexity with the parameters *(m=5, $tau$=2)* for all datasets. 

To classified the patients, we showed that applying the Kmeans algorithm on the HxC feature plane with the following parameters was able to achieve good classification performance:
- Distance metric: `cosine`
- Maximum of Iteration: 100
- Replicates: 1
- Starting cluster centroid: `plus`

== Classification results

#let bg-dbt2 = rgb("e6f0fa")
#let bg-ndbt2 = rgb("e6f5ea")

#figure(
  table(
    columns: (1.2fr, 1fr, 1fr),
    align: (left + horizon, center + horizon, center + horizon),
    stroke: (x, y) => if y == 0 { none } else { 0.5pt + rgb("#e2e8f0") }, // Bordures fines
    table.header([*Dataset*], [*Normalized permutation entropy (H)*], [*MPR complexity (C)*]),
    
    // Groupe NDBT2
    table.cell(fill: bg-dbt2)[*NDBT2*], table.cell(fill: rgb("#6bb5ff"))[0.9518], table.cell(fill: rgb("#6bb5ff"))[0.0791],
    table.cell(fill: bg-dbt2)[*CGMacros + Libre NDBT2*], table.cell(fill: rgb("#ffb639"))[0.9155], table.cell(fill: rgb("#ffb639"))[0.1147],
    table.cell(fill: bg-dbt2)[*CGMacros + Dexcom NDBT2*], table.cell(fill: rgb("#ff7b39"))[0.9129], table.cell(fill: rgb("#ff7b39"))[0.1144],
    table.cell(fill: bg-dbt2)[*NDBT2 + CGMacros*], table.cell(fill: rgb("#ff72c7"))[0.9386], table.cell(fill: rgb("#ff72c7"))[0.0930],
    table.cell(fill: bg-dbt2)[*Hall NDBT2*], table.cell(fill: rgb("#95ff39"))[0.9363], table.cell(fill: rgb("#95ff39"))[0.1071],
    table.hline(stroke: 2pt + rgb("#020202")),
    
    // Groupe DBT2
    table.cell(fill: bg-ndbt2)[*DBT2*], table.cell(fill: rgb("#6bb5ff"))[0.8303], table.cell(fill: rgb("#6bb5ff"))[0.2189],
    table.cell(fill: bg-ndbt2)[*CGMacros + Libre DBT2*], table.cell(fill: rgb("#ffb639"))[0.8164], table.cell(fill: rgb("#ffb639"))[0.2244],
    table.cell(fill: bg-ndbt2)[*CGMacros + Dexcom DBT2*], table.cell(fill: rgb("#ff7b39"))[0.8161], table.cell(fill: rgb("#ff7b39"))[0.2103],
    table.cell(fill: bg-dbt2)[*DBT2 + CGMacros*], table.cell(fill: rgb("#ff72c7"))[0.8171], table.cell(fill: rgb("#ff72c7"))[0.2201],
    table.cell(fill: bg-ndbt2)[*Hall DBT2*], table.cell(fill: rgb("#95ff39"))[0.8580], table.cell(fill: rgb("#95ff39"))[0.1985]
  ),
  caption: [Normalized permutation entropy and MPR complexity for the centroids of each group of patients in the different datasets]
)

== Classification performance of regular PE
With optimized permutation entropy and kmeans algortihm parameters, we obtained the following classification performance inside each dataset:

// Définition des couleurs
#let bg-header = rgb("#f1f5f9") // Ardoise clair pour l'en-tête
#let bg-zebra = rgb("#f8fafc")  // Gris très doux pour l'alternance
#let border-color = rgb("#cbd5e1")

// --- Premier Tableau ---
#figure(
  table(
    columns: (1.5fr, 1fr, 1fr, 1fr, 1fr),
    align: (left + horizon, center + horizon, center + horizon, center + horizon, center + horizon),
    stroke: (x, y) => if y == 0 { none } else { 0.5pt + border-color },
    fill: (x, y) => {
      if y == 0 { bg-header }
      else if calc.even(y) { bg-zebra }
      else { none }
    },
    
    table.header(
      [*Group*], [*Balanced Accuracy*], [*F1-score*], [*Sensibility*], [*Specificity*]
    ),

    [*DBT2/NDBT2*], [0.98], [0.98], [0.95], [0.91],
    [*CGMacros + Dexcom*], [0.79], [0.81], [0.87], [0.71],
    [*CGMacros + Libre*], [0.90], [0.90], [0.87], [0.93],
    [*Average CGMacros*], [0.845], [0.855], [0.87], [0.82],
    [*DBT2/NDBT2 + CGMacros*], [0.93], [0.93], [0.92], [0.94],
    [*Hall*], [0.85], [0.93], [0.89], [0.80]
  ),
  caption: [Classification performance of the Kmeans algorithm applied on the HxC feature plane of the different datasets]
)

Then, we tested the centroids of given datasets to classify the other datasets:

// --- Second Tableau ---
#figure(
  table(
    columns: (1.3fr, 1.3fr, 1fr, 1fr, 1fr, 1fr),
    align: (left + horizon, left + horizon, center + horizon, center + horizon, center + horizon, center + horizon),
    stroke: (x, y) => if y == 0 { none } else { 0.5pt + border-color },
    fill: (x, y) => {
      if y == 0 { bg-header }
      else if calc.even(y) { bg-zebra }
      else { none }
    },

    table.header(
      [*Group*], [*Centroids source*], [*Balanced Accuracy*], [*F1-score*], [*Sensibility*], [*Specificity*]
    ),

    [*CGMacros + Dexcom*], [DBT2/NDBT2], [0.83], [0.81], [0.73], [0.93],
    [*CGMacros + Libre*], [DBT2/NDBT2], [0.93], [0.93], [0.87], [1.00],
    [*Hall*], [DBT2/NDBT2 + CGMacros], [0.86], [0.95], [0.92], [0.80]
  ),
  caption: [Classification performance of the Kmeans algorithm applied on the HxC feature plane of the different datasets using the centroids found with the Kmeans algorithm on other datasets]
)
#pagebreak()
= Going back to the weighted permutation entropy (WPE) 
In order to improve our study, we tried to do the same analysis using this time the weighted permutation entropy. 
We already saw that the best set of parameters to compute the WPE was (m=4, $tau$=2). We then computed the HxC feature plane with these parameters on the different datasets:

== Weigthed permutation entropy and complexity feature plane <WHXC>

*Argentinian DBT2/NDBT2 raw dataset:*
#figure(
  image("figures/Complexity-Weigthed Entropy Plane: Comparison 4-2.png", width: 120%),
  caption: [Comparison of the weighted permutation entropy for DBT2/NDBT2 dataset]
)

#pagebreak()
*CGMacros raw dataset (dexcom and libre probes):*
#figure(
  image("figures/Complexity-Weigthed Entropy Plane: Comparison dexcom 4-2.png", width: 120%),
  caption: [Comparison of the weighted permutation entropy for CGMacros dataset using dexcom probe]
)

#figure(
  image("figures/Complexity-Weigthed Entropy Plane: Comparison libre 4-2.png", width: 120%),
  caption: [Comparison of the weighted permutation entropy for CGMacros dataset using libre probe]
)

*Combined DBT2/NDBT2 and CGMacros raw datasets:*
#figure(
  image("figures/Complexity-Weigthed Entropy Plane: Comparison all 4-2.png", width: 120%),
  caption: [Comparison of the weighted permutation entropy for mixed NDBT2/DBT2 and CGMacros datasets]
)

*Hall raw dataset:*
#figure(
  image("figures/Complexity-Weigthed Entropy Plane: Comparison Hall 4-2.png", width: 120%),
  caption: [Comparison of the weighted permutation entropy for Hall dataset]
)

We already can make several observations:
- As the (m=4, $tau$=2) selected parameters provide well-splitted centroids, we also observe really large standard deviations for WPE and Complexity and this for each group of patient.

- Some points seems also to be outliers, we might need to manually curated the datasets.

Let's first try to apply the Kmeans algorithm on raw datas, at least as a future point of comparison with eventually curated datasets.

== Kmeans algorithm parameters selection with WPE <Wkmeans_param>
We applied the same parameters sweep as in @kmeans_param to the best working dataset i.e. DBT2/NDBT2 this time with (m=4, $tau$=2) parameters.

This time, we achieved to find configurations that hit all 4 best metrics. More precisely, we got 180 "perfect" configurations out of 240 tested.

One more time, we then keep the more simple parameters:
- Distance metric: `sqeuclidean`
- Maximum of Iteration: 100
- Replicates: 1
- Starting cluster centroid: `plus`

#figure(
  image("figures/WHxC K-Means Classification DBT2 4-2.png", width: 120%),
  caption: [Kmeans algorithm applied on the WHxC feature plane of the DBT2/NDBT2 dataset with (m=4, $tau$=2) parameters ]
)

#figure(
  image("figures/Distance to Cluster Centroids WHxC DBT2 4-2.png", width: 120%),
  caption: [Distance to cluster centroids of the Kmeans algorithm applied on the WHxC feature plane of the DBT2/NDBT2 dataset with (m=4, $tau$=2) parameters ]
)

With this and all the "perfect" configurations, we managed to reach the following metrics:
#align(center)[*Balanced Accuracy = 0.97, F1-score = 0.98, Sensibility = 1\ and Specificity = 0.95*]

#nb[
  On the same dataset with the regular permutation entropy, we reached: #align(center)[*Balanced Accuracy = 0.93, F1-score = 0.93, Sensibility = 0.92\ and Specificity = 0.94*]

]

#rslt[
  As it focused more on the variations of the signal, the WPE seems to be a better tools to compute diabetic CGM.
]

== Testing WPE Kmeans robustness on others dataset
We applied the optimized WPE Kmeans algorithm to the others datasets:
#pagebreak()
*CGMacros dataset (dexcom and libre probes)*
#figure(
  image("figures/WHxC K-Means Classification dexcom 4-2.png", width: 120%),
  caption: [Kmeans algorithm applied on the WHxC feature plane of the CGMacros dataset with dexcom probe and (m=4, $tau$=2) parameters ]
)

#figure(
  image("figures/WHxC K-Means Classification libre.png", width: 120%),
  caption: [Kmeans algorithm applied on the WHxC feature plane of the CGMacros dataset with libre probe and (m=4, $tau$=2) parameters ]
) 
#pagebreak()
*Combined dataset DBT2/NDBT2 and CGMacros*
#figure(
  image("figures/WHxC K-Means Classification all .png", width: 120%),
  caption: [Kmeans algorithm applied on the WHxC feature plane of the combined datasets with (m=4, $tau$=2) parameters ]
)

*Hall dataset*

#figure(
  image("figures/WHxC K-Means Classification Hall.png", width: 120%),
  caption: [Kmeans algorithm applied on the WHxC feature plane of the Hall dataset with (m=4, $tau$=2) parameters ]
)

== Classification results with WPE

#let bg-dbt2 = rgb("e6f0fa")
#let bg-ndbt2 = rgb("e6f5ea")

#figure(
  table(
    columns: (1.2fr, 1fr, 1fr),
    align: (left + horizon, center + horizon, center + horizon),
    stroke: (x, y) => if y == 0 { none } else { 0.5pt + rgb("#e2e8f0") }, // Bordures fines
    table.header([*Dataset*], [*Normalized weighted permutation entropy (H)*], [*MPR complexity (C)*]),
    
    // Groupe NDBT2
    table.cell(fill: bg-dbt2)[*NDBT2*], table.cell(fill: rgb("#6bb5ff"))[0.9264], table.cell(fill: rgb("#6bb5ff"))[0.0852],
    table.cell(fill: bg-dbt2)[*CGMacros + Libre NDBT2*], table.cell(fill: rgb("#ffb639"))[0.8857], table.cell(fill: rgb("#ffb639"))[0.1214],
    table.cell(fill: bg-dbt2)[*CGMacros + Dexcom NDBT2*], table.cell(fill: rgb("#ff7b39"))[0.9172], table.cell(fill: rgb("#ff7b39"))[0.0903],
    table.cell(fill: bg-dbt2)[*NDBT2 + CGMacros*], table.cell(fill: rgb("#ff72c7"))[0.9133], table.cell(fill: rgb("#ff72c7"))[0.0962],
    table.cell(fill: bg-dbt2)[*Hall NDBT2*], table.cell(fill: rgb("#95ff39"))[0.9203], table.cell(fill: rgb("#95ff39"))[0.0928],
    table.hline(stroke: 2pt + rgb("#020202")),
    
    // Groupe DBT2
    table.cell(fill: bg-ndbt2)[*DBT2*], table.cell(fill: rgb("#6bb5ff"))[0.7054], table.cell(fill: rgb("#6bb5ff"))[0.2476],
    table.cell(fill: bg-ndbt2)[*CGMacros + Libre DBT2*], table.cell(fill: rgb("#ffb639"))[0.6513], table.cell(fill: rgb("#ffb639"))[0.2659],
    table.cell(fill: bg-ndbt2)[*CGMacros + Dexcom DBT2*], table.cell(fill: rgb("#ff7b39"))[0.7167], table.cell(fill: rgb("#ff7b39"))[0.2396],
    table.cell(fill: bg-dbt2)[*DBT2 + CGMacros*], table.cell(fill: rgb("#ff72c7"))[0.6910], table.cell(fill: rgb("#ff72c7"))[0.2513],
    table.cell(fill: bg-ndbt2)[*Hall DBT2*], table.cell(fill: rgb("#95ff39"))[0.7751], table.cell(fill: rgb("#95ff39"))[0.2100]
  ),
  caption: [Normalized weighted permutation entropy and MPR complexity for the centroids of each group of patients in the different datasets]
)

== Classification performance with WPE
With optimized weigthed permutation entropy and kmeans algortihm parameters, we obtained the following classification performance inside each dataset:

// Définition des couleurs
#let bg-header = rgb("#f1f5f9") // Ardoise clair pour l'en-tête
#let bg-zebra = rgb("#f8fafc")  // Gris très doux pour l'alternance
#let border-color = rgb("#cbd5e1")

// --- Premier Tableau ---
#figure(
  table(
    columns: (1.5fr, 1fr, 1fr, 1fr, 1fr),
    align: (left + horizon, center + horizon, center + horizon, center + horizon, center + horizon),
    stroke: (x, y) => if y == 0 { none } else { 0.5pt + border-color },
    fill: (x, y) => {
      if y == 0 { bg-header }
      else if calc.even(y) { bg-zebra }
      else { none }
    },
    
    table.header(
      [*Group*], [*Balanced Accuracy*], [*F1-score*], [*Sensibility*], [*Specificity*]
    ),

    [*DBT2/NDBT2*], [0.97], [0.98], [1], [0.95],
    [*CGMacros + Dexcom*], [0.86], [0.86], [0.80], [0.93],
    [*CGMacros + Libre*], [0.86], [0.86], [0.80], [0.93],
    [*Average CGMacros*], [0.86], [0.86], [0.80], [0.93],
    [*DBT2/NDBT2 + CGMacros*], [0.91], [0.91], [0.88], [0.94],
    [*Hall*], [0.79], [0.87], [0.79], [0.80]
  ),
  caption: [Classification performance of the Kmeans algorithm applied on the WHxC feature plane of the different datasets]
)

Then, we tested the centroids of given datasets to classify the other datasets:

// --- Second Tableau ---
#figure(
  table(
    columns: (1.3fr, 1.3fr, 1fr, 1fr, 1fr, 1fr),
    align: (left + horizon, left + horizon, center + horizon, center + horizon, center + horizon, center + horizon),
    stroke: (x, y) => if y == 0 { none } else { 0.5pt + border-color },
    fill: (x, y) => {
      if y == 0 { bg-header }
      else if calc.even(y) { bg-zebra }
      else { none }
    },

    table.header(
      [*Group*], [*Centroids source*], [*Balanced Accuracy*], [*F1-score*], [*Sensibility*], [*Specificity*]
    ),

    [*CGMacros + Dexcom*], [DBT2/NDBT2], [0.86], [0.86], [0.80], [0.93],
    [*CGMacros + Libre*], [DBT2/NDBT2], [0.90], [0.89], [0.80], [1.00],
    [*Hall*], [DBT2/NDBT2 + CGMacros], [0.75], [0.92], [0.89], [0.60]
  ),
  caption: [Classification performance of the Kmeans algorithm applied on the WHxC feature plane of the different datasets using the centroids found with the Kmeans algorithm on other datasets]
)
#pagebreak()
= Comparing PE and WPE classification performance on raw datasets

// Color definitions
#let bg-header = rgb("#f1f5f9")
#let bg-zebra = rgb("#f8fafc")
#let bg-section = rgb("#e2e8f0")
#let border-color = rgb("#cbd5e1")
#let pos-green = rgb("#16a34a")
#let neg-red = rgb("#dc2626")
#let neutral-slate = rgb("#64748b")
#let callout-bg = rgb("#f0f9ff")
#let callout-border = rgb("#0284c7")
Below is a direct comparison between standard Shannon Permutation Entropy (PE) and Weighted Permutation Entropy (WPE) across all datasets for both within-dataset kmeans clustering and cross-dataset centroid evaluation.

== Metric-by-Metric Performance Comparison: PE vs. WPE

The following tables present a detailed, metric-by-metric comparison between standard Shannon Permutation Entropy (PE) and Weighted Permutation Entropy (WPE), covering both within-dataset $k$-means clustering and cross-dataset centroid transfer evaluations.

=== Balanced Accuracy Comparison

#figure(
table(
columns: (1.8fr, 1.6fr, 1fr, 1fr, 1.1fr),
align: (left + horizon, left + horizon, center + horizon, center + horizon, center + horizon),
stroke: (x, y) => if y == 0 { none } else { 0.5pt + border-color },
fill: (x, y) => {
if y == 0 { bg-header }
else if y == 1 or y == 8 { bg-section }
else if calc.even(y) { bg-zebra }
else { none }
},

table.header(
  [*Target Group*], [*Evaluation Context / Centroids*], [*PE Acc.*], [*WPE Acc.*], [*Acc. $Delta$*]
),

// Within-dataset
table.cell(colspan: 5)[*Within-Dataset Clustering (Self-Trained Centroids)*],
[*DBT2/NDBT2*], [K-Means (Self)], [0.98], [0.97], text(fill: neg-red)[-0.01],
[*CGMacros + Dexcom*], [K-Means (Self)], [0.79], [0.86], text(fill: pos-green, weight: "bold")[+0.07],
[*CGMacros + Libre*], [K-Means (Self)], [0.90], [0.86], text(fill: neg-red)[-0.04],
[*Average CGMacros*], [K-Means (Self)], [0.845], [0.86], text(fill: pos-green)[+0.015],
[*DBT2/NDBT2 + CGMacros*], [K-Means (Self)], [0.93], [0.91], text(fill: neg-red)[-0.02],
[*Hall*], [K-Means (Self)], [0.85], [0.79], text(fill: neg-red)[-0.06],

// Cross-dataset
table.cell(colspan: 5)[*Cross-Dataset Centroid Validation Transfer*],
[*CGMacros + Dexcom*], [DBT2/NDBT2], [0.83], [0.86], text(fill: pos-green)[+0.03],
[*CGMacros + Libre*], [DBT2/NDBT2], [0.93], [0.90], text(fill: neg-red)[-0.03],
[*Hall*], [DBT2/NDBT2 + CGMacros], [0.86], [0.75], text(fill: neg-red, weight: "bold")[-0.11]


),
caption: [Balanced Accuracy comparison between PE (HxC) and WPE (WHxC) feature spaces.]
)

=== F1-Score Comparison

#figure(
table(
columns: (1.8fr, 1.6fr, 1fr, 1fr, 1.1fr),
align: (left + horizon, left + horizon, center + horizon, center + horizon, center + horizon),
stroke: (x, y) => if y == 0 { none } else { 0.5pt + border-color },
fill: (x, y) => {
if y == 0 { bg-header }
else if y == 1 or y == 8 { bg-section }
else if calc.even(y) { bg-zebra }
else { none }
},

table.header(
  [*Target Group*], [*Evaluation Context / Centroids*], [*PE F1*], [*WPE F1*], [*F1 $Delta$*]
),

// Within-dataset
table.cell(colspan: 5)[*Within-Dataset Clustering (Self-Trained Centroids)*],
[*DBT2/NDBT2*], [K-Means (Self)], [0.98], [0.98], text(fill: neutral-slate)[0.00],
[*CGMacros + Dexcom*], [K-Means (Self)], [0.81], [0.86], text(fill: pos-green, weight: "bold")[+0.05],
[*CGMacros + Libre*], [K-Means (Self)], [0.90], [0.86], text(fill: neg-red)[-0.04],
[*Average CGMacros*], [K-Means (Self)], [0.855], [0.86], text(fill: pos-green)[+0.005],
[*DBT2/NDBT2 + CGMacros*], [K-Means (Self)], [0.93], [0.91], text(fill: neg-red)[-0.02],
[*Hall*], [K-Means (Self)], [0.93], [0.87], text(fill: neg-red)[-0.06],

// Cross-dataset
table.cell(colspan: 5)[*Cross-Dataset Centroid Validation Transfer*],
[*CGMacros + Dexcom*], [DBT2/NDBT2], [0.81], [0.86], text(fill: pos-green)[+0.05],
[*CGMacros + Libre*], [DBT2/NDBT2], [0.93], [0.89], text(fill: neg-red)[-0.04],
[*Hall*], [DBT2/NDBT2 + CGMacros], [0.95], [0.92], text(fill: neg-red)[-0.03]


),
caption: [F1-Score performance comparison between PE and WPE.]
)

== Sensitivity Comparison

#figure(
table(
columns: (1.8fr, 1.6fr, 1fr, 1fr, 1.1fr),
align: (left + horizon, left + horizon, center + horizon, center + horizon, center + horizon),
stroke: (x, y) => if y == 0 { none } else { 0.5pt + border-color },
fill: (x, y) => {
if y == 0 { bg-header }
else if y == 1 or y == 8 { bg-section }
else if calc.even(y) { bg-zebra }
else { none }
},

table.header(
  [*Target Group*], [*Evaluation Context / Centroids*], [*PE Sens.*], [*WPE Sens.*], [*Sens. $Delta$*]
),

// Within-dataset
table.cell(colspan: 5)[*Within-Dataset Clustering (Self-Trained Centroids)*],
[*DBT2/NDBT2*], [K-Means (Self)], [0.95], [1.00], text(fill: pos-green)[+0.05],
[*CGMacros + Dexcom*], [K-Means (Self)], [0.87], [0.80], text(fill: neg-red)[-0.07],
[*CGMacros + Libre*], [K-Means (Self)], [0.87], [0.80], text(fill: neg-red)[-0.07],
[*Average CGMacros*], [K-Means (Self)], [0.87], [0.80], text(fill: neg-red)[-0.07],
[*DBT2/NDBT2 + CGMacros*], [K-Means (Self)], [0.92], [0.88], text(fill: neg-red)[-0.04],
[*Hall*], [K-Means (Self)], [0.89], [0.79], text(fill: neg-red, weight: "bold")[-0.10],

// Cross-dataset
table.cell(colspan: 5)[*Cross-Dataset Centroid Validation Transfer*],
[*CGMacros + Dexcom*], [DBT2/NDBT2], [0.73], [0.80], text(fill: pos-green)[+0.07],
[*CGMacros + Libre*], [DBT2/NDBT2], [0.87], [0.80], text(fill: neg-red)[-0.07],
[*Hall*], [DBT2/NDBT2 + CGMacros], [0.92], [0.89], text(fill: neg-red)[-0.03]


),
caption: [Sensitivity (True Positive Rate) comparison between PE and WPE.]
)

== Specificity Comparison

#figure(
table(
columns: (1.8fr, 1.6fr, 1fr, 1fr, 1.1fr),
align: (left + horizon, left + horizon, center + horizon, center + horizon, center + horizon),
stroke: (x, y) => if y == 0 { none } else { 0.5pt + border-color },
fill: (x, y) => {
if y == 0 { bg-header }
else if y == 1 or y == 8 { bg-section }
else if calc.even(y) { bg-zebra }
else { none }
},

table.header(
  [*Target Group*], [*Evaluation Context / Centroids*], [*PE Spec.*], [*WPE Spec.*], [*Spec. $Delta$*]
),

// Within-dataset
table.cell(colspan: 5)[*Within-Dataset Clustering (Self-Trained Centroids)*],
[*DBT2/NDBT2*], [K-Means (Self)], [0.91], [0.95], text(fill: pos-green)[+0.04],
[*CGMacros + Dexcom*], [K-Means (Self)], [0.71], [0.93], text(fill: pos-green, weight: "bold")[+0.22],
[*CGMacros + Libre*], [K-Means (Self)], [0.93], [0.93], text(fill: neutral-slate)[0.00],
[*Average CGMacros*], [K-Means (Self)], [0.82], [0.93], text(fill: pos-green, weight: "bold")[+0.11],
[*DBT2/NDBT2 + CGMacros*], [K-Means (Self)], [0.94], [0.94], text(fill: neutral-slate)[0.00],
[*Hall*], [K-Means (Self)], [0.80], [0.80], text(fill: neutral-slate)[0.00],

// Cross-dataset
table.cell(colspan: 5)[*Cross-Dataset Centroid Validation Transfer*],
[*CGMacros + Dexcom*], [DBT2/NDBT2], [0.93], [0.93], text(fill: neutral-slate)[0.00],
[*CGMacros + Libre*], [DBT2/NDBT2], [1.00], [1.00], text(fill: neutral-slate)[0.00],
[*Hall*], [DBT2/NDBT2 + CGMacros], [0.80], [0.60], text(fill: neg-red, weight: "bold")[-0.20]


),
caption: [Specificity (True Negative Rate) comparison between PE and WPE.]
)

#rslt[
#text(weight: "bold", size: 11pt)[Key Analytical Insights per Metric:]
- *Balanced Accuracy*: WPE shows significant improvements on high-variance CGM signals (Dexcom: $+0.07$ self, $+0.03$ transfer), while regular PE performs better on smoother datasets (Hall: $-0.06$ self, $-0.11$ transfer).
- *F1-Score*: WPE matches or exceeds PE on Dexcom ($+0.05$), maintaining overall competitive F1-scores across diabetic populations.
- *Sensitivity*: Standard PE maintains a generally higher sensitivity across most groups, whereas WPE trades some sensitivity for lower false-alarm rates.
- *Specificity*: WPE's primary advantage is in specificity on noisy devices, showing an outstanding $+0.22$ gain on Dexcom in self-clustering and maintaining $1.00$ on Libre centroid transfer.
]

#pagebreak()
= Currating the datasets
As we saw in @WHXC, the weighted permutation entropy makes appear more outliers in the datasets then the regular PE. We now tried to curate datasets in order to better compare PE and WPE performances.

== Spotting the outliers
We should now define a criteria to spot the outliers. To stay consistent with on the previous work, we will use the distance to the cluster centroids as a criteria, obtained with the Kmeans algorithm using optimized parameters of @Wkmeans_param.


=== Illustration of the curation method on the DBT2/NDBT2 dataset
Here are the uncurated WHxC feature plane of the diabetics patients of the DBT2/NDBT2 dataset:

#figure(
  image("figures/WHxC Feature Plane - DBT2 (m=4, tau=2).png", width: 120%),
  caption: [Weighted Permutation Entropy Feature Plane - DBT2 (m=4, tau=2)]
)

Just by looking at the figure, we can suppose that the points 1, 3 and 15 are good candidates to be outliers.
We then computed the distance to the cluster centroids:

#figure(
  image("figures/Centroid Distance per Point - DBT2.png", width: 120%),
  caption: [Distance to cluster centroids for each point of the DBT2/NDBT2 dataset using the Kmeans algorithm with optimized parameters (m=4, tau=2)]
)
As thresolds, we used the standard deviation and the doubled of the standard deviation of the distances to the cluster centroids. 
And indeed, 1, 3 and 15 are largely above the first standard deviation thresold and even to the doubled standard deviation one for some. We can then consider removing these points to build the curated dataset.

After applying the same process on the non diabetic patients of the same dataset, we obtained the following kmeans performances:

#figure(
  image("figures/WHxC K-Means Classification DBT2 curated.png", width: 120%),
  caption: [Kmeans algorithm applied on the WHxC feature plane of the curated DBT2/NDBT2 dataset with (m=4, $tau$=2) parameters ]
)

#figure(
  image("figures/Distance to Cluster Centroids DBT2 curated.png", width: 100%),
)

Perfect performances! It is not very surprising given the fact that we used the DBT2/NDBT2 dataset to calibrate the (m, $tau$) parameters and the Kmeans algorithm parameters. But it is a good sign that the curation method is working well.

== Kmeans algorithm performances with WPE on curated datasets
After currating all the datasets, we carried the same analysiswith (m=4, $tau$=2) parameters and Kmeans algorithm parameters:
- Distance metric: `sqeuclidean`
- Maximum of Iteration: 100
- Replicates: 1
- Starting cluster centroid: `plus`

#figure(
  table(
    columns: (1.2fr, 1fr, 1fr),
    align: (left + horizon, center + horizon, center + horizon),
    stroke: (x, y) => if y == 0 { none } else { 0.5pt + rgb("#e2e8f0") }, // Bordures fines
    table.header([*Curated dataset*], [*Normalized weighted permutation entropy (H)*], [*MPR complexity (C)*]),
    
    // Groupe NDBT2
    table.cell(fill: bg-dbt2)[*NDBT2*], table.cell(fill: rgb("#6bb5ff"))[0.9386], table.cell(fill: rgb("#6bb5ff"))[0.0733],
    table.cell(fill: bg-dbt2)[*CGMacros + Libre NDBT2*], table.cell(fill: rgb("#ffb639"))[0.8857], table.cell(fill: rgb("#ffb639"))[0.1225],
    table.cell(fill: bg-dbt2)[*CGMacros + Dexcom NDBT2*], table.cell(fill: rgb("#ff7b39"))[0.9241], table.cell(fill: rgb("#ff7b39"))[0.0835],
    table.cell(fill: bg-dbt2)[*NDBT2 + CGMacros*], table.cell(fill: rgb("#ff72c7"))[0.9192], table.cell(fill: rgb("#ff72c7"))[0.0903],
    table.cell(fill: bg-dbt2)[*Hall NDBT2*], table.cell(fill: rgb("#95ff39"))[0.9117], table.cell(fill: rgb("#95ff39"))[0.1010],
    table.hline(stroke: 2pt + rgb("#020202")),
    
    // Groupe DBT2
    table.cell(fill: bg-ndbt2)[*DBT2*], table.cell(fill: rgb("#6bb5ff"))[0.7210], table.cell(fill: rgb("#6bb5ff"))[0.2429],
    table.cell(fill: bg-ndbt2)[*CGMacros + Libre DBT2*], table.cell(fill: rgb("#ffb639"))[0.6458], table.cell(fill: rgb("#ffb639"))[0.2698],
    table.cell(fill: bg-ndbt2)[*CGMacros + Dexcom DBT2*], table.cell(fill: rgb("#ff7b39"))[0.7123], table.cell(fill: rgb("#ff7b39"))[0.2431],
    table.cell(fill: bg-dbt2)[*DBT2 + CGMacros*], table.cell(fill: rgb("#ff72c7"))[0.6958], table.cell(fill: rgb("#ff72c7"))[0.2510],
    table.cell(fill: bg-ndbt2)[*Hall DBT2*], table.cell(fill: rgb("#95ff39"))[0.6575], table.cell(fill: rgb("#95ff39"))[0.2707]
  ),
  caption: [Normalized weighted permutation entropy and MPR complexity for the centroids of each group of patients in the different *curated* datasets]
)

We then obtained the following classification performance inside each dataset:

// Définition des couleurs
#let bg-header = rgb("#f1f5f9") // Ardoise clair pour l'en-tête
#let bg-zebra = rgb("#f8fafc")  // Gris très doux pour l'alternance
#let border-color = rgb("#cbd5e1")

// --- Premier Tableau ---
#figure(
  table(
    columns: (1.5fr, 1fr, 1fr, 1fr, 1fr),
    align: (left + horizon, center + horizon, center + horizon, center + horizon, center + horizon),
    stroke: (x, y) => if y == 0 { none } else { 0.5pt + border-color },
    fill: (x, y) => {
      if y == 0 { bg-header }
      else if calc.even(y) { bg-zebra }
      else { none }
    },
    
    table.header(
      [*Curated group*], [*Balanced Accuracy*], [*F1-score*], [*Sensibility*], [*Specificity*]
    ),

    [*DBT2/NDBT2*], [1.00], [1.00], [1.00], [1.00],
    [*CGMacros + Dexcom*], [0.96], [0.96], [0.92], [1.00],
    [*CGMacros + Libre*], [1.00], [1.00], [1.00], [1.00],
    [*Average CGMacros*], [0.98], [0.98], [0.96], [1.00],
    [*DBT2/NDBT2 + CGMacros*], [0.99], [0.99], [0.97], [1.00],
    [*Hall*], [0.88], [0.98], [1.00], [0.75]
  ),
  caption: [Classification performance of the Kmeans algorithm applied on the WHxC feature plane of the different datasets]
)

Then, we tested the centroids of given datasets to classify the other datasets:

// --- Second Tableau ---
#figure(
  table(
    columns: (1.3fr, 1.3fr, 1fr, 1fr, 1fr, 1fr),
    align: (left + horizon, left + horizon, center + horizon, center + horizon, center + horizon, center + horizon),
    stroke: (x, y) => if y == 0 { none } else { 0.5pt + border-color },
    fill: (x, y) => {
      if y == 0 { bg-header }
      else if calc.even(y) { bg-zebra }
      else { none }
    },

    table.header(
      [*Curated group*], [*Centroids source*], [*Balanced Accuracy*], [*F1-score*], [*Sensibility*], [*Specificity*]
    ),

    [*CGMacros + Dexcom*], [DBT2/NDBT2], [0.96], [0.96], [0.92], [1.00],
    [*CGMacros + Libre*], [DBT2/NDBT2], [1.00], [1.00], [1.00], [1.00],
    [*Hall*], [DBT2/NDBT2 + CGMacros], [0.88], [0.98], [1.00], [0.75]
  ),
  caption: [Classification performance of the Kmeans algorithm applied on the WHxC feature plane of the different datasets using the centroids found with the Kmeans algorithm on other datasets]
)

== Metric-by-Metric Performance Comparison: PE vs. WPE on raw and curated datasets

We then added the performances on curated datasets to the previous comparison between PE and WPE on raw datasets. We can see that the performances are really improved with curated datasets, especially for the Hall dataset.

=== Balanced Accuracy Comparison

#figure(
table(
columns: (1.8fr, 1.6fr, 0.9fr, 1.1fr, 1.3fr, 1.1fr),
align: (left + horizon, left + horizon, center + horizon, center + horizon, center + horizon, center + horizon),
stroke: (x, y) => if y == 0 { none } else { 0.5pt + border-color },
fill: (x, y) => {
if y == 0 { bg-header }
else if y == 1 or y == 8 { bg-section }
else if calc.even(y) { bg-zebra }
else { none }
},

table.header(
  [*Target Group*], [*Evaluation Context / Centroids*], [*PE Acc.*], [*WPE raw Acc.*], [*WPE curated Acc.*], [*Acc. $Delta$*]
),

// Within-dataset
table.cell(colspan: 6)[*Within-Dataset Clustering (Self-Trained Centroids)*],
[*DBT2/NDBT2*], [K-Means (Self)], [0.98], [0.97], [1.00], text(fill: pos-green)[+0.03],
[*CGMacros + Dexcom*], [K-Means (Self)], [0.79], [0.86], [0.96], text(fill: pos-green, weight: "bold")[+0.10],
[*CGMacros + Libre*], [K-Means (Self)], [0.90], [0.86], [1.00], text(fill: pos-green, weight: "bold")[+0.14],
[*Average CGMacros*], [K-Means (Self)], [0.845], [0.86], [0.98], text(fill: pos-green, weight: "bold")[+0.12],
[*DBT2/NDBT2 + CGMacros*], [K-Means (Self)], [0.93], [0.91], [0.99], text(fill: pos-green)[+0.08],
[*Hall*], [K-Means (Self)], [0.85], [0.79], [0.88], text(fill: pos-green)[+0.09],

// Cross-dataset
table.cell(colspan: 6)[*Cross-Dataset Centroid Validation Transfer*],
[*CGMacros + Dexcom*], [DBT2/NDBT2], [0.83], [0.86], [0.96], text(fill: pos-green, weight: "bold")[+0.10],
[*CGMacros + Libre*], [DBT2/NDBT2], [0.93], [0.90], [1.00], text(fill: pos-green, weight: "bold")[+0.10],
[*Hall*], [DBT2/NDBT2 + CGMacros], [0.86], [0.75], [0.88], text(fill: pos-green, weight: "bold")[+0.13]

),
caption: [Balanced Accuracy comparison between PE, WPE raw, and WPE curated feature spaces.]
)

=== F1-Score Comparison

#figure(
table(
columns: (1.8fr, 1.6fr, 0.9fr, 1.1fr, 1.3fr, 1.1fr),
align: (left + horizon, left + horizon, center + horizon, center + horizon, center + horizon, center + horizon),
stroke: (x, y) => if y == 0 { none } else { 0.5pt + border-color },
fill: (x, y) => {
if y == 0 { bg-header }
else if y == 1 or y == 8 { bg-section }
else if calc.even(y) { bg-zebra }
else { none }
},

table.header(
  [*Target Group*], [*Evaluation Context / Centroids*], [*PE F1*], [*WPE raw F1*], [*WPE curated F1*], [*F1 $Delta$*]
),

// Within-dataset
table.cell(colspan: 6)[*Within-Dataset Clustering (Self-Trained Centroids)*],
[*DBT2/NDBT2*], [K-Means (Self)], [0.98], [0.98], [1.00], text(fill: pos-green)[+0.02],
[*CGMacros + Dexcom*], [K-Means (Self)], [0.81], [0.86], [0.96], text(fill: pos-green, weight: "bold")[+0.10],
[*CGMacros + Libre*], [K-Means (Self)], [0.90], [0.86], [1.00], text(fill: pos-green, weight: "bold")[+0.14],
[*Average CGMacros*], [K-Means (Self)], [0.855], [0.86], [0.98], text(fill: pos-green, weight: "bold")[+0.12],
[*DBT2/NDBT2 + CGMacros*], [K-Means (Self)], [0.93], [0.91], [0.99], text(fill: pos-green)[+0.08],
[*Hall*], [K-Means (Self)], [0.93], [0.87], [0.98], text(fill: pos-green, weight: "bold")[+0.11],

// Cross-dataset
table.cell(colspan: 6)[*Cross-Dataset Centroid Validation Transfer*],
[*CGMacros + Dexcom*], [DBT2/NDBT2], [0.81], [0.86], [0.96], text(fill: pos-green, weight: "bold")[+0.10],
[*CGMacros + Libre*], [DBT2/NDBT2], [0.93], [0.89], [1.00], text(fill: pos-green, weight: "bold")[+0.11],
[*Hall*], [DBT2/NDBT2 + CGMacros], [0.95], [0.92], [0.98], text(fill: pos-green)[+0.06]

),
caption: [F1-Score performance comparison between PE, WPE raw, and WPE curated.]
)

== Sensitivity Comparison

#figure(
table(
columns: (1.8fr, 1.6fr, 0.9fr, 1.1fr, 1.3fr, 1.1fr),
align: (left + horizon, left + horizon, center + horizon, center + horizon, center + horizon, center + horizon),
stroke: (x, y) => if y == 0 { none } else { 0.5pt + border-color },
fill: (x, y) => {
if y == 0 { bg-header }
else if y == 1 or y == 8 { bg-section }
else if calc.even(y) { bg-zebra }
else { none }
},

table.header(
  [*Target Group*], [*Evaluation Context / Centroids*], [*PE Sens.*], [*WPE raw Sens.*], [*WPE curated Sens.*], [*Sens. $Delta$*]
),

// Within-dataset
table.cell(colspan: 6)[*Within-Dataset Clustering (Self-Trained Centroids)*],
[*DBT2/NDBT2*], [K-Means (Self)], [0.95], [1.00], [1.00], text(fill: neutral-slate)[0.00],
[*CGMacros + Dexcom*], [K-Means (Self)], [0.87], [0.80], [0.92], text(fill: pos-green, weight: "bold")[+0.12],
[*CGMacros + Libre*], [K-Means (Self)], [0.87], [0.80], [1.00], text(fill: pos-green, weight: "bold")[+0.20],
[*Average CGMacros*], [K-Means (Self)], [0.87], [0.80], [0.96], text(fill: pos-green, weight: "bold")[+0.16],
[*DBT2/NDBT2 + CGMacros*], [K-Means (Self)], [0.92], [0.88], [0.97], text(fill: pos-green)[+0.09],
[*Hall*], [K-Means (Self)], [0.89], [0.79], [1.00], text(fill: pos-green, weight: "bold")[+0.21],

// Cross-dataset
table.cell(colspan: 6)[*Cross-Dataset Centroid Validation Transfer*],
[*CGMacros + Dexcom*], [DBT2/NDBT2], [0.73], [0.80], [0.92], text(fill: pos-green, weight: "bold")[+0.12],
[*CGMacros + Libre*], [DBT2/NDBT2], [0.87], [0.80], [1.00], text(fill: pos-green, weight: "bold")[+0.20],
[*Hall*], [DBT2/NDBT2 + CGMacros], [0.92], [0.89], [1.00], text(fill: pos-green, weight: "bold")[+0.11]

),
caption: [Sensitivity (True Positive Rate) comparison between PE, WPE raw, and WPE curated.]
)

== Specificity Comparison

#figure(
table(
columns: (1.8fr, 1.6fr, 0.9fr, 1.1fr, 1.3fr, 1.1fr),
align: (left + horizon, left + horizon, center + horizon, center + horizon, center + horizon, center + horizon),
stroke: (x, y) => if y == 0 { none } else { 0.5pt + border-color },
fill: (x, y) => {
if y == 0 { bg-header }
else if y == 1 or y == 8 { bg-section }
else if calc.even(y) { bg-zebra }
else { none }
},

table.header(
  [*Target Group*], [*Evaluation Context / Centroids*], [*PE Spec.*], [*WPE raw Spec.*], [*WPE curated Spec.*], [*Spec. $Delta$*]
),

// Within-dataset
table.cell(colspan: 6)[*Within-Dataset Clustering (Self-Trained Centroids)*],
[*DBT2/NDBT2*], [K-Means (Self)], [0.91], [0.95], [1.00], text(fill: pos-green)[+0.05],
[*CGMacros + Dexcom*], [K-Means (Self)], [0.71], [0.93], [1.00], text(fill: pos-green)[+0.07],
[*CGMacros + Libre*], [K-Means (Self)], [0.93], [0.93], [1.00], text(fill: pos-green)[+0.07],
[*Average CGMacros*], [K-Means (Self)], [0.82], [0.93], [1.00], text(fill: pos-green)[+0.07],
[*DBT2/NDBT2 + CGMacros*], [K-Means (Self)], [0.94], [0.94], [1.00], text(fill: pos-green)[+0.06],
[*Hall*], [K-Means (Self)], [0.80], [0.80], [0.75], text(fill: neg-red)[-0.05],

// Cross-dataset
table.cell(colspan: 6)[*Cross-Dataset Centroid Validation Transfer*],
[*CGMacros + Dexcom*], [DBT2/NDBT2], [0.93], [0.93], [1.00], text(fill: pos-green)[+0.07],
[*CGMacros + Libre*], [DBT2/NDBT2], [1.00], [1.00], [1.00], text(fill: neutral-slate)[0.00],
[*Hall*], [DBT2/NDBT2 + CGMacros], [0.80], [0.60], [0.75], text(fill: pos-green, weight: "bold")[+0.15]

),
caption: [Specificity (True Negative Rate) comparison between PE, WPE raw, and WPE curated.]
)

#pagebreak()
= To try next
== Multi-dimensional
- 2-D Permutation Entropy (see EntropyHUB) //see in the documentation how it's defined

== Mono-dimensional
- Fourier Spectrum
- AUC (power density)