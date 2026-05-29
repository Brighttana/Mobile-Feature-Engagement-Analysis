# Mobile App Feature Engagement & Retention Analysis
# Product Analytics Case Study: Premium Subscription Hub Launch

# Load necessary packages
library(tidyverse)
library(scales)

setwd("C:/Users/Brighton/OneDrive/Documents/GitHub/Mobile-Feature-Engagement-Analysis")

# ==========================================
# 1. DATA SIMULATION (Building Event Logs)
# ==========================================
set.seed(42) # Ensures reproducibility
n_users <- 5000

print("Initializing database generation for mobile app user sessions...")

user_behavior_data <- tibble(
  User_ID = 10000 + 1:n_users,
  Device = sample(c("iOS", "Android"), n_users, replace = TRUE, prob = c(0.6, 0.4)),
  Acquisition_Channel = sample(c("Paid Ads", "Organic Search", "Referral"), n_users, replace = TRUE, prob = c(0.5, 0.3, 0.2)),
  
  # Tracking conversion funnel steps (1 = Yes, 0 = Dropped Off)
  Step1_Open_App = 1,
  Step2_View_Subscription_Hub = rbinom(n_users, 1, 0.75),    # 75% transition rate
  Step3_Click_Subscription_Offer = rbinom(n_users, 1, 0.40), # 40% click rate
  Step4_Complete_Purchase = rbinom(n_users, 1, 0.25)        # 25% final conversion rate
) %>%
  # Enforce logical funnel dependencies (cannot complete a step if dropped out earlier)
  mutate(
    Step3_Click_Subscription_Offer = if_else(Step2_View_Subscription_Hub == 0, 0, Step3_Click_Subscription_Offer),
    Step4_Complete_Purchase = if_else(Step3_Click_Subscription_Offer == 0, 0, Step4_Complete_Purchase),
    
    # Core Feature Engagement Grouping
    Engaged_With_Hub = if_else(Step2_View_Subscription_Hub == 1, "Engaged User", "Non-Engaged User"),
    
    # Simulate Retention (Users who discover the hub feature retain at a higher percentage)
    Base_Retention_Prob = if_else(Engaged_With_Hub == "Engaged User", 0.815, 0.567),
    Day_30_Retained = rbinom(n_users, 1, Base_Retention_Prob)
  )

# ==========================================
# 2. PRODUCT METRICS PIPELINE (Aggregation)
# ==========================================

print("Aggregating journey logs into milestone conversion metrics...")

# Calculate total users at each stage for funnel tracking
funnel_summary <- user_behavior_data %>%
  summarise(
    `1. Sessions Started` = sum(Step1_Open_App),
    `2. Hub Viewed` = sum(Step2_View_Subscription_Hub),
    `3. Offer Clicked` = sum(Step3_Click_Subscription_Offer),
    `4. Purchase Completed` = sum(Step4_Complete_Purchase)
  ) %>%
  pivot_longer(cols = everything(), names_to = "Funnel_Stage", values_to = "User_Count") %>%
  mutate(Conversion_Rate = (User_Count / n_users) * 100)

print(funnel_summary)

# ==========================================
# 3. HIGH-IMPACT PRODUCT VISUALIZATIONS
# ==========================================

print("Plotting User Conversion Funnel...")

# Chart 1: Funnel Drop-off Plot
ggplot(funnel_summary, aes(x = reorder(Funnel_Stage, -User_Count), y = User_Count, fill = Funnel_Stage)) +
  geom_bar(stat = "identity", width = 0.6, show.legend = FALSE) +
  geom_text(aes(label = paste0(comma(User_Count), " (", round(Conversion_Rate, 1), "%)")), 
            vjust = -0.5, fontface = "bold", size = 4) +
  scale_fill_brewer(palette = "Blues", direction = -1) +
  theme_minimal(base_size = 12) +
  labs(
    title = "Product Conversion Funnel Drop-off Analysis",
    subtitle = "Evaluating Mobile App Friction Across Premium Subscription Hub Milestone Stages",
    x = "User Journey Step",
    y = "Active User Sessions",
    caption = "Sample Cohort: N = 5,000 Users | Product Analytics Case Study"
  ) +
  theme(
    plot.title = element_text(face = "bold", size = 15, color = "#222222"),
    plot.subtitle = element_text(size = 11, color = "#555555"),
    panel.grid.minor = element_blank()
  )

# Force export directly into the working directory folder
ggsave(filename = paste0(getwd(), "/product_funnel_chart.png"), width = 9, height = 5.5, dpi = 300)


print("Plotting Cohort Retention Comparison...")

# Aggregate data for cohort retention tracking
retention_summary <- user_behavior_data %>%
  group_by(Engaged_With_Hub) %>%
  summarise(
    Total_Users = n(),
    Retained_Users = sum(Day_30_Retained),
    Retention_Rate = (Retained_Users / Total_Users) * 100
  )

# Chart 2: Retention Comparison Plot
ggplot(retention_summary, aes(x = Engaged_With_Hub, y = Retention_Rate, fill = Engaged_With_Hub)) +
  geom_bar(stat = "identity", width = 0.4, show.legend = FALSE) +
  geom_text(aes(label = paste0(round(Retention_Rate, 1), "% Day-30 Retention")), 
            vjust = -0.5, fontface = "bold", size = 4.5) +
  scale_fill_manual(values = c("Engaged User" = "#2ca02c", "Non-Engaged User" = "#d62728")) +
  ylim(0, 100) +
  theme_minimal(base_size = 12) +
  labs(
    title = "Premium Feature Engagement Impact on App Retention",
    subtitle = "Comparing Day-30 Retention Rates: Subscription Hub Viewers vs. Non-Viewers",
    x = "User Cohort Group",
    y = "Day-30 Retention Rate (%)",
    caption = "Analysis verifies feature discovery correlates strongly with long-term app retention."
  ) +
  theme(
    plot.title = element_text(face = "bold", size = 15, color = "#222222"),
    plot.subtitle = element_text(size = 11, color = "#555555"),
    panel.grid.minor = element_blank()
  )

# Absolute Path Fix: Forcing images into the exact folder where this script lives
current_folder <- dirname(rstudioapi::getSourceEditorContext()$path)
# Saving directly to the core C drive folder to bypass OneDrive lockouts
ggsave(filename = "C:/Users/Brighton/product_funnel_chart.png", width = 9, height = 5.5, dpi = 300)
ggsave(filename = "C:/Users/Brighton/feature_retention_impact.png", width = 9, height = 5.5, dpi = 300)

print("Pipeline execution complete! Both charts deployed directly to your repository path.")

# PART 2

# Install and load the power analysis library
if(!require(pwr)) install.packages("pwr")
library(pwr)

# Define baseline funnel metrics
baseline_conversion <- 0.45  # 45% mid-funnel conversion
target_conversion <- 0.50    # 50% target (5% absolute lift)

# Calculate Cohen's h effect size for proportions
effect_size <- pwr.2p.test(h = ES.h(baseline_conversion, target_conversion), 
                           sig.level = 0.05, 
                           power = 0.80)

print(effect_size)
# This outputs the exact sample size required per variant (Treatment vs. Control)

#PART 3

library(ggplot2)

# Simulated actual experiment results based on power calculations
# Group A: Control (Old Flow) | Group B: Treatment (Interactive Tool-tip)
experiment_data <- matrix(c(1450, 1750,  # Group A: Converted (1450), Dropped (1750) -> Total: 3200
                            1632, 1568), # Group B: Converted (1632), Dropped (1568) -> Total: 3200
                          nrow = 2, byrow = TRUE,
                          dimnames = list(Group = c("Control_A", "Treatment_B"),
                                          Outcome = c("Converted", "Dropped")))

# Statistical Verification via Chi-Square Test
chisq_result <- chisq.test(experiment_data)
print(chisq_result)

# Generate a publication-quality statistical visual for recruiters
df_plot <- data.frame(
  Group = c("Control A", "Control A", "Treatment B", "Treatment B"),
  Outcome = c("Converted", "Dropped", "Converted", "Dropped"),
  Count = c(1450, 1750, 1632, 1568)
)

# Calculate percentages for the visualization
df_plot$Percentage <- c(1450/3200, 1750/3200, 1632/3200, 1568/3200) * 100

ggplot(df_plot, aes(x = Group, y = Percentage, fill = Outcome)) +
  geom_bar(stat = "identity", position = "stack", width = 0.6) +
  geom_text(aes(label = paste0(round(Percentage, 1), "%")), 
            position = position_stack(vjust = 0.5), color = "white", fontface = "bold") +
  scale_fill_manual(values = c("#1f77b4", "#d62728")) +
  labs(title = "A/B Test Results: Interactive Tool-tip Engagement Lift",
       subtitle = paste("Chi-Square p-value:", round(chisq_result$p.value, 4), "(Statistically Significant)"),
       x = "User Cohort Variant", y = "Conversion Composition (%)") +
  theme_minimal()

# Save image directly to manual copy directory
ggsave("C:/Users/Brighton/ab_test_experiment_results.png", width = 8, height = 5, dpi = 300)

