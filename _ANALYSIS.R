library(tidyverse)
library(readxl)
library(scales)
library(rstudioapi)

setwd(dirname(getActiveDocumentContext()$path))
getActiveDocumentContext()$path
# --- Import Data ----
energyIntensity = read_excel("C:/Users/joshl/OneDrive - Colostate/Research/NAWI/Git Simulink Folder/ARC/ARC_Complete/_RESULTS.xlsx", 
                              sheet = "EnergyIntensity-kWhMG", range = "A1:D4")

costperMG = read_excel("C:/Users/joshl/OneDrive - Colostate/Research/NAWI/Git Simulink Folder/ARC/ARC_Complete/_RESULTS.xlsx", 
                       sheet = "EnergyCosts-$MG", range = "A1:E10")

demandCharge = read_excel("C:/Users/joshl/OneDrive - Colostate/Research/NAWI/Git Simulink Folder/ARC/ARC_Complete/_RESULTS.xlsx", 
                          sheet = "RelativeCostChange-Demand", range = "A1:E10")

energyCharge = read_excel("C:/Users/joshl/OneDrive - Colostate/Research/NAWI/Git Simulink Folder/ARC/ARC_Complete/_RESULTS.xlsx", 
                          sheet = "RelativeCostChange-Energy", range = "A1:E10")

#==== Energy Intensity Plot ====
df_long <- energyIntensity %>%
  pivot_longer(
    cols      = c(`Steady State Operations`, `Solar-Responsive`, `TOU-Responsive`),
    names_to  = 'Controls Approach',
    values_to = 'EnergyIntensity'
  ) %>%
  mutate(
    Controller = factor(`Controls Approach`,
                        levels = c('Steady State Operations', 'Solar-Responsive', 'TOU-Responsive'),
                        labels = c('Steady State', 'Solar-Responsive', 'TOU-Responsive')),
    Solar = factor(recode(as.character(Solar),
                          'High Solar'      = 'Expanded (1.3 MW)',
                          'Baseline Solar'  = 'Existing (0.3 MW)',
                          'No Solar'        = 'None'),
                   levels = c('Expanded (1.3 MW)', 'Existing (0.3 MW)', 'None')),    # Delta from Steady State within each solar group
    Delta = EnergyIntensity - EnergyIntensity[Controller == 'Steady State'],
    .by = Solar
  )

# --- Plot ---
ggplot(df_long, aes(x = EnergyIntensity, y = Solar, color = Controller)) +
  
  # Connecting line between dots
  geom_line(color = 'grey70', linewidth = 0.8) +
  facet_wrap(.~Solar, scales = "free", ncol = 1) +
  # Dots
  geom_point(size = 5) +
  
  # Delta annotations above non-reference dots
  geom_text(
    data     = df_long %>% filter(Controller != 'Steady State'),
    aes(label = paste0(ifelse(Delta >= 0, '+', ''),
                      signif(Delta, 4))),
    vjust    = -1.1,
    size     = 3.2,
    fontface = 'bold'
  ) +
  
  scale_color_manual(values = c(
    'Steady State'     = '#2c7bb6',
    'Solar-Responsive' = '#fdae61',
    'TOU-Responsive'   = '#d7191c'
  )) +
  
  
  labs(
    title    = 'Solar and Operational Scenario Energy Intenstiy',
    x        = 'Energy Intensity, kWh/MG Permeate',
    y        = NULL,
  ) +
  
  theme_minimal(base_size = 13) +
  theme(
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank(),
    legend.position    = 'top',
    plot.title         = element_text(face = 'bold'),
    axis.text.y        = element_blank()
  )

ggsave("Visualizations/EnergyIntensity.png", width = 8, height = 4)
#==== Demand CHarge Plot ====
# --- Pivot to long format ---
df_long <- demandCharge %>%
  pivot_longer(
    cols      = c(`Steady State Operations`, `Solar-Responsive`, `TOU-Responsive`),
    names_to  = 'Controls Approach',
    values_to = 'Rel_Demand_Charge'
  ) %>%
  select(-TOU) %>% #Drop TOU column. Not needed here.
  mutate(
    Controller = factor(`Controls Approach`,
                        levels = c('Steady State Operations', 'Solar-Responsive', 'TOU-Responsive'),
                        labels = c('Steady State', 'Solar-Responsive', 'TOU-Responsive')),
    Solar = factor(recode(as.character(Solar),
                                 'High Solar'      = 'Expanded (1.3 MW)',
                                 'Baseline Solar'  = 'Existing (0.3 MW)',
                                 'No Solar'        = 'None'),
                          levels = c('Expanded (1.3 MW)', 'Existing (0.3 MW)', 'None')),    # Delta from Steady State within each solar group
    Delta = Rel_Demand_Charge - Rel_Demand_Charge[Controller == 'Steady State'],
    .by = Solar
  )

red = 
# --- Filter to Existing Solar only ---
df_existing <- df_long %>% filter(Solar == "Existing (0.3 MW)")
ref_existing <- ref %>% filter(Solar == "Existing (0.3 MW)")

# --- Plot ---
ggplot(df_existing, aes(x = Rel_Demand_Charge, y = Solar, color = Controller)) +
  
  # Connecting line between dots
  geom_line(aes(group = Solar), color = 'grey70', linewidth = 0.8) +
  
  # Dots
  geom_point(size = 5) +
  
  # Delta annotations above non-reference dots
  geom_text(
    data     = df_existing %>% filter(Controller != 'Steady State'),
    aes(label = paste0(ifelse(Delta >= 0, '+', ''),
                       scales::percent(Delta, accuracy = 0.1))),
    vjust    = -1.1,
    size     = 5,
    fontface = 'bold'
  ) +
  
  # Absolute percent label below Steady State dot
  # geom_text(
  #   data  = ref_existing,
  #   aes(label = scales::percent(Rel_Demand_Charge, accuracy = 0.1)),
  #   vjust = 2.2,
  #   size  = 3.2,
  #   color = 'grey40'
  # ) +
  
  scale_color_manual(values = c(
    'Steady State'     = '#2c7bb6',
    'Solar-Responsive' = '#fdae61',
    'TOU-Responsive'   = '#d7191c'
  )) +
  
  scale_x_continuous(
    labels = scales::percent_format(accuracy = 0.1),
    expand = expansion(mult = 0.15)
  ) +
  
  labs(
    title    = 'Relative Demand Charge Change',
    subtitle = 'Winter Billing Structure',
    x        = 'Relative Demand Charge Change (%)',
    y        = NULL,
    color    = 'Controls Approach'
  ) +
  
  theme_minimal(base_size = 13) +
  theme(
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank(),
    legend.position    = 'top',
    plot.title         = element_text(face = 'bold'),
    axis.text.y        = element_text(face = 'bold', size = 11)
  )

ggsave("Visualizations/RelDem.png", width = 8, height = 4)

#======Cost Intensity Plot=========

# --- Reference point: Baseline Solar + Steady State (average across TOU since similar) ---
reference <- mean(costperMG$`Steady State Operations`[costperMG$Solar == 'Baseline Solar'])

# --- Pivot to long format ---
df_long_mg <- costperMG %>%
  pivot_longer(
    cols      = c(`Steady State Operations`, `Solar-Responsive`, `TOU-Responsive`),
    names_to  = 'Controller',
    values_to = 'Cost'
  ) %>%
  mutate(
    Controller = factor(Controller,
                        levels = c('Steady State Operations', 'Solar-Responsive', 'TOU-Responsive'),
                        labels = c('Steady State', 'Solar-Responsive', 'TOU-Responsive')),
    Solar = factor(recode(as.character(Solar),
                          'High Solar'     = 'Expanded (1.3 MW)',
                          'Baseline Solar' = 'Existing (0.3 MW)',
                          'No Solar'       = 'None'),
                   levels = c('Expanded (1.3 MW)', 'Existing (0.3 MW)', 'None')),
    TOU = factor(recode(as.character(TOU),
                        'High TOU'     = 'Greater TOU Variance (+50%)',
                        'Baseline TOU' = 'Existing TOU Rates',
                        'No TOU'       = 'Static TOU'),
                 levels = c('Greater TOU Variance (+50%)', 'Existing TOU Rates', 'Static TOU')),
    Delta      = Cost - reference,
    bar_bottom = pmin(0, Delta),
    bar_top    = pmax(0, Delta),
    Direction  = case_when(
      Delta <  0 ~ 'Savings',
      Delta >  0 ~ 'Cost Increase',
      TRUE       ~ 'Reference'
    ),
    Label = paste0(Solar, '\n', Controller)
  ) %>%
  mutate(Label = factor(Label, levels = unique(Label)))

# --- Rebuild df_plot WITHOUT collapsing TOU this time ---
df_plot <- df_long_mg %>%
  mutate(
    Label_facet = Controller  # x-axis just shows controller within each facet
  )

# --- Pre-compute for use outside aes() ---
top_y     <- max(df_plot$bar_top)
vjust_vec <- ifelse(df_plot$Delta >= 0, 0, 1)

# --- Plot ---
ggplot(df_plot, aes(x = as.numeric(Controller), fill = Direction)) +
  
  # Zero reference line
  geom_hline(yintercept = 0, linewidth = 0.8,
             color = 'grey30', linetype = 'dashed') +
  
  # Waterfall bars
  geom_rect(aes(xmin = as.numeric(Controller) - 0.4,
                xmax = as.numeric(Controller) + 0.4,
                ymin = bar_bottom,
                ymax = bar_top),
            color = 'white', linewidth = 0.4) +
  
  # Delta labels above/below each bar
  geom_text(
    aes(x     = as.numeric(Controller),
        y     = ifelse(Delta >= 0, bar_top + 0.3, bar_bottom - 0.3),
        label = paste0(ifelse(Delta >= 0, '+', ''), round(Delta, 2))),
    vjust    = vjust_vec,
    size     = 2.8,
    fontface = 'bold'
  ) +
  
  # Absolute cost label inside each bar
  geom_text(
    aes(x     = as.numeric(Controller),
        y     = (bar_bottom + bar_top) / 2,
        label = round(Cost, 2)),
    size     = 3,
    color    = 'white',
    fontface = 'bold'
  ) +
  
  # Separator lines between solar groups
  geom_vline(xintercept = c(1.5, 2.5),
             linetype = 'dotted', color = 'grey50', linewidth = 0.5) +
  
  scale_x_continuous(
    breaks = 1:3,
    labels = c('Steady State', 'Solar-\nResponsive', 'TOU-\nResponsive')
  ) +
  
  scale_y_continuous(expand = expansion(mult = 0.15)) +
  
  scale_fill_manual(values = c(
    'Savings'       = 'darkgreen',
    'Cost Increase' = '#d7191c',
    'Reference'     = '#808080'
  )) +
  
  # Facet by TOU, strip on top; rows = Solar groups
  facet_grid(Solar ~ TOU) +
  
  labs(
    title    = 'Energy Cost per MG Permeate',
    subtitle = paste0('Reference = $', round(reference, 2), ' per MG Permeate'),
    x        = 'Controls Approach',
    y        = 'Energy Cost Deviation from Reference ($/MG)'
  ) +
  
  theme_minimal(base_size = 14) +
  theme(
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank(),
    legend.position    = 'none',            # legend removed
    plot.title         = element_text(face = 'bold'),
    axis.text.x        = element_text(size = 10, lineheight = 1.3),
    strip.text         = element_text(face = 'bold', size = 12),
    strip.background   = element_rect(fill = 'grey93', color = NA),
    panel.spacing      = unit(0.8, 'lines'),
    panel.background = element_rect(fill = NA)
  )

ggsave("Analysis\EnergyCosts_RelChange.png", width = 12, height = 10)
